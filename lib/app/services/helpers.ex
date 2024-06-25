defmodule App.Services.Helpers do
  def encode_image_hash(image_url) when is_binary(image_url) do
    with {:ok, binary} <- fetch_image(image_url),
         {:ok, image} <- Image.from_binary(binary),
         {width, height, _} <- Image.shape(image),
         {:ok, hash} <- Image.Blurhash.encode(image) do
      {hash, width, height}
    else
      _ ->
        nil
    end
  end

  def encode_image_hash(_), do: nil

  def fetch_image(image_url) do
    case Req.get(image_url) do
      {:ok, resp} ->
        if resp.status == 200 and content_type_is_image?(resp) do
          {:ok, resp.body}
        else
          {:error, resp.status}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  def content_type_is_image?(response) do
    response
    |> Req.Response.get_header("content-type")
    |> case do
      ["image/png"] -> true
      ["image/jpeg"] -> true
      ["image/webp"] -> true
      ["image/gif"] -> true
      _ -> false
    end
  end
end
