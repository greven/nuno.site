defmodule Site.Gallery.Uploader do
  @moduledoc """
  Processes gallery photos in the admin UI.

  For each photo this:

    1. copies the uploaded file into a local staging directory
    2. runs the same ImageMagick transformations as `mix images`
       (resize to 2048px, optimize, webp/avif, 400x400 thumbnail, blur)
    3. uploads every generated variant to the R2 photos bucket
    4. adds the photo metadata to `priv/content/photos.json`

  This is meant to run in development only: it shells out to ImageMagick and
  relies on the local R2 credentials being configured.
  """

  alias Site.Gallery
  alias Site.Images

  @quality 80
  @resize_size "2048"
  @thumbnail_size "400x400"

  @gravity_values ~w(center north south east west northwest northeast southwest southeast)

  # File suffixes generated per photo by Site.Images for the settings above.
  @variant_suffixes ~w(.jpg .webp .avif _thumbnail_400w.jpg _blur.jpg)

  @doc """
  Processes a batch of uploaded photos.

  `entries` is a list of `{ref, client_name, tmp_path}` tuples,
  as produced by `Phoenix.LiveView.Upload.consume_uploaded_entries/3`.

  `meta` maps each `ref` to the metadata submitted in the form:
  (`%{"title" => ..., "gravity" => ..., "date" => ...}`).

  Options:

    * `:notify` - a pid to receive progress messages
    * `:uploader` - a fun `(key, body, content_type) -> :ok | {:error, reason}`;
      defaults to uploading to the photos bucket
    * `:work_dir` - staging directory (default `"tmp/gallery"`)

  Progress messages sent to `notify`:

    * `{:photo_progress, ref, :processing}`
    * `{:photo_progress, ref, {:ok, entry}}`
    * `{:photo_progress, ref, {:error, reason}}`
    * `{:photos_finished, %{ok: [entries], errors: [{ref, reason}]}}`

  Returns `%{ok: [manifest entries], errors: [{ref, reason}]}`.
  """
  def process(entries, meta \\ %{}, opts \\ []) when is_list(entries) do
    notify = Keyword.get(opts, :notify)
    uploader = Keyword.get(opts, :uploader, &upload_to_r2/3)
    work_dir = Keyword.get(opts, :work_dir, default_work_dir())

    try do
      File.mkdir_p!(work_dir)
      run_batch(entries, meta, notify, uploader, work_dir)
    rescue
      exception -> batch_error(notify, exception)
    end
  end

  defp run_batch(entries, meta, notify, uploader, work_dir) do
    {results, _used_ids} =
      entries
      |> Enum.map_reduce(existing_ids(), fn {ref, client_name, tmp_path}, used_ids ->
        send_progress(notify, {:photo_progress, ref, :processing})

        result =
          try do
            process_one(
              client_name,
              tmp_path,
              Map.get(meta, ref, %{}),
              work_dir,
              uploader,
              used_ids
            )
          rescue
            exception -> {:error, Exception.message(exception)}
          end

        send_progress(notify, {:photo_progress, ref, result})

        used_ids =
          case result do
            {:ok, photo} -> [photo["id"] | used_ids]
            _ -> used_ids
          end

        {{ref, result}, used_ids}
      end)

    ok_photos = for {_ref, {:ok, photo}} <- results, do: photo
    errors = for {ref, {:error, reason}} <- results, do: {ref, reason}

    {ok_photos, errors} = update_manifest(ok_photos, errors)

    # Only remove staged files once they are safely in the manifest.
    if ok_photos != [] do
      cleanup(work_dir, for(photo <- ok_photos, do: photo["id"]))
    end

    if notify, do: send(notify, {:photos_finished, %{ok: ok_photos, errors: errors}})

    %{ok: ok_photos, errors: errors}
  end

  @doc """
  Returns `true` when the photo's main file exists in the R2 bucket.
  """
  def photo_in_cdn?(photo_id) when is_binary(photo_id) do
    Site.CDN.object_exists?(object_key("#{photo_id}.jpg"))
  end

  @doc """
  Removes a photo from the manifest and deletes all of its generated files
  from the R2 bucket (`gallery/<id>.jpg`, `.webp`, `.avif`, thumbnail and
  blur variants).

  Options:

    * `:deleter` - a fun `(key) -> :ok | {:error, reason}`; defaults to
      deleting from the R2 bucket

  Returns `:ok` or `{:error, reason}`. The manifest is updated first, so a
  failed CDN deletion leaves the site consistent (with orphaned files that
  can be cleaned up later).
  """
  def delete_photo(photo_id, opts \\ []) when is_binary(photo_id) do
    deleter = Keyword.get(opts, :deleter, &delete_from_r2/1)

    with :ok <- Gallery.remove_photos([photo_id]) do
      delete_cdn_files(photo_id, deleter)
    end
  end

  defp delete_cdn_files(photo_id, deleter) do
    [
      "#{photo_id}.jpg",
      "#{photo_id}.webp",
      "#{photo_id}.avif",
      "#{photo_id}_thumbnail_400w.jpg",
      "#{photo_id}_blur.jpg"
    ]
    |> Enum.map(&object_key/1)
    |> Enum.reduce_while(:ok, fn key, :ok ->
      case deleter.(key) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, "deleting #{key} failed: #{format_error(reason)}"}}
      end
    end)
  end

  defp delete_from_r2(key) do
    case Site.CDN.delete_object(key) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  # Always report a terminal state so the UI never stays stuck "processing".
  defp batch_error(notify, exception) do
    message = Exception.message(exception)
    if notify, do: send(notify, {:photos_finished, %{ok: [], errors: [{:batch, message}]}})
    %{ok: [], errors: [{:batch, message}]}
  end

  defp update_manifest([], errors), do: {[], errors}

  defp update_manifest(ok_photos, errors) do
    case Gallery.add_photos(ok_photos) do
      :ok ->
        {ok_photos, errors}

      {:error, reason} ->
        # Keep the staged files around so the batch can be retried.
        {[], [{:manifest, reason} | errors]}
    end
  end

  @doc """
  Returns `nil` when the R2 bucket is configured, or an error message
  when a required setting is missing from the `.env`.
  """
  def config_error do
    config = Site.CDN.config()

    cond do
      config.bucket in [nil, "", "bucket-name"] ->
        "R2_BUCKET_NAME is not set in your .env (the R2 bucket is required)."

      config.endpoint_url in [nil, "", "public-endpoint-url"] ->
        "R2_ENDPOINT_URL is not set in your .env."

      not is_binary(config.access_key_id) or config.access_key_id == "" ->
        "R2_ACCESS_KEY_ID is not set in your .env."

      not is_binary(config.secret_access_key) or config.secret_access_key == "" ->
        "R2_SECRET_ACCESS_KEY is not set in your .env."

      true ->
        nil
    end
  end

  @doc """
  Copies an uploaded file into the staging directory and returns the
  staged path.

  LiveView deletes uploaded temp files as soon as the upload entry is
  consumed, so this must be called inside the `consume_uploaded_entries/3`
  callback while the file still exists.
  """
  def stage_upload(ref, tmp_path) do
    dir = staging_dir()
    File.mkdir_p!(dir)

    dest = Path.join(dir, "#{ref}-#{Path.basename(tmp_path)}")
    File.cp!(tmp_path, dest)
    dest
  end

  @doc """
  Builds a manifest entry map for a processed photo.

  Returns `{:ok, entry}` or `{:error, reason}` when the date is invalid.
  """
  def build_entry(id, meta, width, height) do
    with {:ok, date} <- parse_date(Map.get(meta, "date")) do
      {:ok,
       %{
         "id" => id,
         "key" => "#{id}.jpg",
         "title" => string_or_nil(Map.get(meta, "title")),
         "description" => string_or_nil(Map.get(meta, "description")),
         "album" => string_or_nil(Map.get(meta, "album")),
         "width" => width,
         "height" => height,
         "date" => date,
         "location" => string_or_nil(Map.get(meta, "location")),
         "camera" => string_or_nil(Map.get(meta, "camera")),
         "added" => Date.to_iso8601(Date.utc_today()),
         "tags" => parse_tags(Map.get(meta, "tags"))
       }}
    end
  end

  defp process_one(client_name, tmp_path, meta, work_dir, uploader, used_ids) do
    base_id = normalize_id(Map.get(meta, "id"), client_name)
    id = unique_id(base_id, used_ids)

    source_path = Path.join(work_dir, "#{id}.jpg")
    File.cp!(tmp_path, source_path)
    File.rm(tmp_path)

    opts = [
      resize: @resize_size,
      quality: @quality,
      thumbnail: true,
      thumbnail_size: @thumbnail_size,
      gravity: gravity(Map.get(meta, "gravity")),
      blur: true
    ]

    with :ok <- Images.process(source_path, opts),
         {:ok, {width, height}} <- Images.get_dimensions(source_path),
         {:ok, entry} <- build_entry(id, meta, width, height),
         :ok <- upload_variants(id, work_dir, uploader) do
      {:ok, entry}
    end
  end

  # Derive the photo id: prefer the user-provided id, fall back to a slug of
  # the file name. Always slugified: ids end up in file names and URLs.
  defp normalize_id(user_id, client_name) do
    base =
      if is_binary(user_id) && String.trim(user_id) != "" do
        Images.slugify(user_id)
      else
        Images.slugify(client_name)
      end

    if base == "", do: "photo", else: base
  end

  # Make sure the id is unique against the photos already in the manifest
  # and against ids already used in the current batch.
  defp unique_id(base_id, existing_ids) do
    if base_id in existing_ids do
      first_available_suffix(base_id, existing_ids)
    else
      base_id
    end
  end

  defp existing_ids do
    Enum.map(Gallery.list_photos(), & &1.id)
  end

  defp first_available_suffix(base_id, existing_ids) do
    Stream.iterate(1, &(&1 + 1))
    |> Enum.find_value(fn n ->
      candidate = "#{base_id}-#{n}"
      if candidate in existing_ids, do: nil, else: candidate
    end)
  end

  defp gravity(value) when value in @gravity_values, do: value
  defp gravity(_), do: "center"

  defp parse_date(nil), do: {:ok, nil}
  defp parse_date(""), do: {:ok, nil}

  defp parse_date(date) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, parsed} -> {:ok, Date.to_iso8601(parsed)}
      {:error, _} -> {:error, "invalid date #{inspect(date)} (expected YYYY-MM-DD)"}
    end
  end

  defp parse_date(_), do: {:error, "invalid date (expected YYYY-MM-DD)"}

  defp string_or_nil(nil), do: nil

  defp string_or_nil(value) when is_binary(value) do
    trimmed = String.trim(value)
    if trimmed == "", do: nil, else: trimmed
  end

  defp string_or_nil(_), do: nil

  # Normalize tags into the manifest format: a `;`-separated string.
  # Commas are accepted as separators too, to be forgiving.
  defp parse_tags(nil), do: nil

  defp parse_tags(tags) when is_binary(tags) do
    tags = tags |> String.replace(",", ";") |> String.trim()
    if tags == "", do: nil, else: tags
  end

  defp parse_tags(_), do: nil

  defp upload_variants(id, work_dir, uploader) do
    variants = [
      {"#{id}.jpg", "image/jpeg"},
      {"#{id}.webp", "image/webp"},
      {"#{id}.avif", "image/avif"},
      {"#{id}_thumbnail_400w.jpg", "image/jpeg"},
      {"#{id}_blur.jpg", "image/jpeg"}
    ]

    Enum.reduce_while(variants, :ok, fn {file_name, content_type}, :ok ->
      key = object_key(file_name)

      case upload_variant(uploader, key, file_name, content_type, work_dir) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  # Gallery objects live in the bucket under the `gallery/` prefix, which is
  # what `Site.Gallery.cdn_path/0` maps to on the public CDN URL.
  defp object_key(file_name) do
    gallery_path = Gallery.cdn_path() |> String.trim_leading("/")
    "#{gallery_path}/#{file_name}"
  end

  defp upload_variant(uploader, key, file_name, content_type, work_dir) do
    path = Path.join(work_dir, file_name)

    case File.read(path) do
      {:ok, body} ->
        case uploader.(key, body, content_type) do
          :ok -> :ok
          {:error, reason} -> {:error, "uploading #{key} failed: #{format_error(reason)}"}
        end

      {:error, reason} ->
        {:error, "generated variant #{file_name} is missing: #{:file.format_error(reason)}"}
    end
  end

  defp upload_to_r2(key, body, content_type) do
    case Site.CDN.put_object(key, body, content_type: content_type) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp format_error({status, body}) when is_integer(status),
    do: "HTTP #{status}: #{inspect(body)}"

  defp format_error(%{__exception__: true} = exception), do: Exception.message(exception)
  defp format_error(reason), do: inspect(reason)

  defp cleanup(work_dir, ids) do
    for id <- ids, suffix <- @variant_suffixes do
      File.rm(Path.join(work_dir, "#{id}#{suffix}"))
    end

    :ok
  end

  defp default_work_dir do
    Application.get_env(:site, :gallery_upload_dir, "tmp/gallery")
  end

  defp staging_dir do
    Path.join(default_work_dir(), "_staging")
  end

  defp send_progress(nil, _message), do: :ok
  defp send_progress(pid, message) when is_pid(pid), do: send(pid, message)
end
