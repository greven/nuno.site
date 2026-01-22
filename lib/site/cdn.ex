defmodule Site.CDN do
  @moduledoc """
  Module for accessing Object Storage CDN (S3-compatible API).

  ## Configuration

  The following application configuration (set via environment variables):

    * `:base_url` - Public CDN URL (e.g., "https://cdn.nuno.site")
    * `:access_key_id` - R2 access key ID
    * `:secret_access_key` - R2 secret access key
    * `:endpoint_url` - R2 account endpoint URL
    * `:bucket` - R2 bucket name

  ## Examples

      # List objects with a prefix
      {:ok, objects} = Site.CDN.list_objects("images/")

      # Upload a file
      {:ok, _response} = Site.CDN.put_object("images/photo.jpg", File.read!("photo.jpg"))

      # Download a file
      {:ok, content} = Site.CDN.get_object("images/photo.jpg")

      # Delete a file
      {:ok, _response} = Site.CDN.delete_object("images/photo.jpg")

      # Check if file exists
      true = Site.CDN.object_exists?("images/photo.jpg")

      # Generate public CDN URL
      url = Site.CDN.cdn_url("images/photo.jpg")
      # => "https://cdn.nuno.site/images/photo.jpg"

      # Generate presigned URL for temporary access
      presigned_url = Site.CDN.presign_url("private/doc.pdf", expires_in: :timer.minutes(30))
  """

  @doc """
  Returns the CDN configuration.

  ## Examples

      iex> config = Site.CDN.config()
      iex> config.bucket
      "my-bucket"
  """
  def config do
    %{
      base_url: Application.get_env(:site, :cdn)[:base_url],
      access_key_id: Application.get_env(:site, :cdn)[:access_key_id],
      secret_access_key: Application.get_env(:site, :cdn)[:secret_access_key],
      endpoint_url: Application.get_env(:site, :cdn)[:endpoint_url],
      bucket: Application.get_env(:site, :cdn)[:bucket]
    }
  end

  @doc """
  Lists objects in the S3/R2 bucket with an optional prefix filter.

  Returns a list of objects matching the given prefix. Each object is a map
  containing metadata such as Key, Size, LastModified, etc.

  ## Parameters

    * `prefix` - Optional prefix to filter objects (default: "")

  ## Returns

    * `{:ok, list}` - List of object maps from the bucket
    * `{:error, reason}` - Error tuple with reason

  ## Examples

      # List all objects
      {:ok, objects} = Site.CDN.list_objects()

      # List objects with prefix
      {:ok, images} = Site.CDN.list_objects("images/")
      # => {:ok, [%{"Key" => "images/photo1.jpg", "Size" => 1024, ...}, ...]}
  """
  def list_objects(prefix \\ "") do
    config = config()
    req = build_req()

    url = "s3://#{config.bucket}"
    params = if prefix != "", do: [prefix: prefix], else: []

    case Req.get(req, url: url, params: params) do
      {:ok, response} when response.status == 200 ->
        objects = parse_list_objects_response(response.body)
        {:ok, objects}

      {:ok, response} ->
        {:error, {response.status, response.body}}

      {:error, exception} ->
        {:error, exception}
    end
  end

  @doc """
  Gets an object from the S3/R2 bucket.

  Downloads and returns the contents of the specified object.

  ## Parameters

    * `key` - The object key (path) in the bucket

  ## Returns

    * `{:ok, binary}` - The object content as binary data
    * `{:error, :not_found}` - Object does not exist
    * `{:error, reason}` - Other errors

  ## Examples

      {:ok, content} = Site.CDN.get_object("images/photo.jpg")
      File.write!("local-photo.jpg", content)
  """
  def get_object(key) do
    config = config()
    req = build_req()

    url = "s3://#{config.bucket}/#{key}"

    case Req.get(req, url: url) do
      {:ok, response} when response.status == 200 ->
        {:ok, response.body}

      {:ok, response} when response.status == 404 ->
        {:error, :not_found}

      {:ok, response} ->
        {:error, {response.status, response.body}}

      {:error, exception} ->
        {:error, exception}
    end
  end

  @doc """
  Uploads an object to the S3/R2 bucket.

  Uploads the given content to the specified key in the bucket.

  ## Parameters

    * `key` - The object key (path) in the bucket
    * `body` - The content to upload (binary or iodata)
    * `opts` - Optional keyword list with options:
      * `:content_type` - MIME type of the content (default: "application/octet-stream")

  ## Returns

    * `{:ok, response}` - Upload successful
    * `{:error, reason}` - Upload failed

  ## Examples

      # Upload binary content
      {:ok, _} = Site.CDN.put_object("data.json", Jason.encode!(%{key: "value"}))

      # Upload with content type
      {:ok, _} = Site.CDN.put_object(
        "images/photo.jpg",
        File.read!("photo.jpg"),
        content_type: "image/jpeg"
      )
  """
  def put_object(key, body, opts \\ []) do
    config = config()
    req = build_req()

    url = "s3://#{config.bucket}/#{key}"
    content_type = Keyword.get(opts, :content_type, "application/octet-stream")

    headers = [{"content-type", content_type}]

    case Req.put(req, url: url, body: body, headers: headers) do
      {:ok, response} when response.status in 200..299 ->
        {:ok, :uploaded}

      {:ok, response} ->
        {:error, {response.status, response.body}}

      {:error, exception} ->
        {:error, exception}
    end
  end

  @doc """
  Deletes an object from the S3/R2 bucket.

  ## Parameters

    * `key` - The object key (path) to delete

  ## Returns

    * `{:ok, :deleted}` - Deletion successful
    * `{:error, reason}` - Deletion failed

  ## Examples

      {:ok, :deleted} = Site.CDN.delete_object("images/old-photo.jpg")
  """
  def delete_object(key) do
    config = config()
    req = build_req()

    url = "s3://#{config.bucket}/#{key}"

    case Req.delete(req, url: url) do
      {:ok, response} when response.status in 200..299 ->
        {:ok, :deleted}

      {:ok, response} when response.status == 404 ->
        {:ok, :deleted}

      {:ok, response} ->
        {:error, {response.status, response.body}}

      {:error, exception} ->
        {:error, exception}
    end
  end

  @doc """
  Checks if an object exists in the S3/R2 bucket.

  Uses a HEAD request to efficiently check for object existence without
  downloading the content.

  ## Parameters

    * `key` - The object key (path) to check

  ## Returns

    * `true` - Object exists
    * `false` - Object does not exist

  ## Examples

      if Site.CDN.object_exists?("images/photo.jpg") do
        IO.puts("Photo exists!")
      end
  """
  def object_exists?(key) do
    config = config()
    req = build_req()

    url = "s3://#{config.bucket}/#{key}"

    case Req.head(req, url: url) do
      {:ok, response} when response.status == 200 -> true
      {:ok, response} when response.status == 404 -> false
      {:error, _} -> false
    end
  end

  @doc """
  Generates the public CDN URL for a given object key.

  This returns the public URL that can be used to access the object via
  the CDN if the object has public read permissions.

  ## Parameters

    * `key` - The object key (path) in the bucket

  ## Returns

    * `String.t()` - The full CDN URL

  ## Examples

      url = Site.CDN.cdn_url("images/photo.jpg")
      # => "https://cdn.nuno.site/images/photo.jpg"
  """
  def cdn_url(key) do
    config = config()
    base_url = String.trim_trailing(config.base_url, "/")
    key = String.trim_leading(key, "/")

    "#{base_url}/#{key}"
  end

  @doc """
  Generates a presigned URL for temporary access to a private object.

  Creates a URL that grants temporary access to a private object without
  requiring authentication. The URL expires after 24 hours (default from ReqS3).

  Note: The underlying `ReqS3.presign_url/1` function does not support custom
  expiration times. Use `presign_upload_form/2` if you need custom expiration.

  ## Parameters

    * `key` - The object key (path) in the bucket
    * `opts` - Optional keyword list with options:
      * `:region` - AWS region (default: "us-east-1")

  ## Returns

    * `{:ok, url}` - Presigned URL string (expires in 24 hours)
    * `{:error, reason}` - Error generating URL

  ## Examples

      # Generate URL with default 24-hour expiration
      {:ok, url} = Site.CDN.presign_url("private/doc.pdf")

      # Use with custom region
      {:ok, url} = Site.CDN.presign_url("downloads/file.zip", region: "us-east-1")
  """
  def presign_url(key, opts \\ []) do
    config = config()

    options = [
      endpoint_url: config.endpoint_url,
      access_key_id: config.access_key_id,
      secret_access_key: config.secret_access_key,
      bucket: config.bucket,
      key: key
    ]

    # Add region if specified in opts, otherwise defaults to us-east-1
    options =
      case Keyword.get(opts, :region) do
        nil -> options
        region -> Keyword.put(options, :region, region)
      end

    try do
      presigned_url = ReqS3.presign_url(options)
      {:ok, presigned_url}
    rescue
      exception ->
        {:error, exception}
    end
  end

  @doc """
  Generates a presigned form for direct browser upload to S3/R2.

  Creates form data that allows a client (browser) to upload directly to S3/R2
  without proxying through your server. Useful for large file uploads.

  ## Parameters

    * `key` - The object key (path) where the file will be uploaded
    * `opts` - Optional keyword list with options:
      * `:content_type` - Restrict uploads to this MIME type
      * `:max_size` - Maximum file size in bytes
      * `:expires_in` - Duration in milliseconds before form expires (default: 1 hour)

  ## Returns

    * `{:ok, %{url: url, fields: fields}}` - Form data for upload
    * `{:error, reason}` - Error generating form

  ## Examples

      # Basic presigned form
      {:ok, form} = Site.CDN.presign_upload_form("uploads/file.pdf")
      # form.url => "https://..."
      # form.fields => [{"key", "uploads/file.pdf"}, {"policy", "..."}, ...]

      # Restrict to images only, max 5MB
      {:ok, form} = Site.CDN.presign_upload_form(
        "images/photo.jpg",
        content_type: "image/jpeg",
        max_size: 5 * 1024 * 1024,
        expires_in: :timer.minutes(30)
      )

  ## Usage in Phoenix LiveView

      # In the LiveView
      form = Site.CDN.presign_upload_form!("uploads/\#{file_name}")

      # In the template
      <form action={form.url} method="post" enctype="multipart/form-data">
        <%= for {name, value} <- form.fields do %>
          <input type="hidden" name={name} value={value} />
        <% end %>
        <input type="file" name="file" />
        <button type="submit">Upload</button>
      </form>
  """
  def presign_upload_form(key, opts \\ []) do
    config = config()
    expires_in = Keyword.get(opts, :expires_in, :timer.hours(1))

    options =
      [
        access_key_id: config.access_key_id,
        secret_access_key: config.secret_access_key,
        bucket: config.bucket,
        key: key,
        endpoint_url: config.endpoint_url,
        expires_in: expires_in
      ]
      |> maybe_add_option(:content_type, opts)
      |> maybe_add_option(:max_size, opts)

    try do
      form = ReqS3.presign_form(options)
      {:ok, form}
    rescue
      exception ->
        {:error, exception}
    end
  end

  ##  Private Functions

  defp build_req do
    config = config()

    Req.new()
    |> ReqS3.attach(
      aws_sigv4: [
        access_key_id: config.access_key_id,
        secret_access_key: config.secret_access_key,
        region: "us-east-1"
      ],
      aws_endpoint_url_s3: config.endpoint_url
    )
  end

  defp parse_list_objects_response(body) when is_map(body) do
    body
    |> get_in(["ListBucketResult", "Contents"])
    |> case do
      nil -> []
      contents when is_list(contents) -> contents
      contents when is_map(contents) -> [contents]
    end
  end

  defp parse_list_objects_response(_body), do: []

  defp maybe_add_option(options, key, opts) do
    case Keyword.get(opts, key) do
      nil -> options
      value -> Keyword.put(options, key, value)
    end
  end
end
