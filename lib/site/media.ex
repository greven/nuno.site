defmodule Site.Media do
  @moduledoc """
  Media-related utilities and functions.
  """

  @doc """
  Given an image src path, return the corresponding blurred image path.
  """
  def image_blur_path(src) do
    String.replace(src, ~r/\.(jpg|jpeg|png|gif)$/, "_blur.jpg")
  end

  @doc """
  Check if a blurred version of an image src path exists in the static assets
  and cache the result.
  """
  def image_blur_exists?(src) do
    case Site.Cache.get({:image_blur_exists, src}) do
      nil ->
        exists? = blur_image_exists?(src)
        Site.Cache.put({:image_blur_exists, src}, exists?, ttl: :timer.hours(48))
        exists?

      exists ->
        exists
    end
  end

  defp blur_image_exists?(src) do
    [:code.priv_dir(:site), "static", image_blur_path(src)]
    |> Path.join()
    |> File.exists?()
  end
end
