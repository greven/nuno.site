defmodule Site.Media do
  @moduledoc """
  Media-related utilities and functions.
  """

  @doc """
  Given an image src path, return the corresponding blurred image path.
  """
  def image_blur_path(src) when is_binary(src) do
    cond do
      String.contains?(src, "_blur.") -> src
      true -> String.replace(src, ~r/\.(jpg|jpeg|png|gif)$/, "_blur.jpg")
    end
  end

  def image_blur_path(_), do: nil

  @doc """
  Check if a blurred version of an image src path exists.
  If src is a URI, return it, otherwise check if the blur
  image exists in the static assets and cache the result.
  """
  def image_blur_exists?(%URI{} = uri), do: uri

  def image_blur_exists?(src) when is_binary(src) do
    site_cdn_host = site_cdn_host()

    src
    |> URI.new()
    |> case do
      {:ok, %URI{host: ^site_cdn_host}} ->
        true

      _ ->
        case Site.Cache.get({:image_blur_exists, src}) do
          nil ->
            exists? = blur_image_exists_in_static?(src)
            Site.Cache.put({:image_blur_exists, src}, exists?, ttl: :timer.hours(48))
            exists?

          exists ->
            exists
        end
    end
  end

  defp blur_image_exists_in_static?(src) do
    [:code.priv_dir(:site), "static", image_blur_path(src)]
    |> Path.join()
    |> File.exists?()
  end

  def site_cdn_host do
    Application.get_env(:site, :cdn_url, "https://cdn.nuno.site")
    |> URI.new!()
    |> Map.get(:host)
  end
end
