defmodule Mix.Tasks.Images.Upload do
  use Mix.Task

  @shortdoc "Process and upload blog post images to R2"

  # @switches [
  # quality: :integer,
  # skip_upload: :boolean
  # ]

  def run(_argv) do
    # {opts, args} = OptionParser.parse!(argv, strict: @switches)

    # case args do
    #   [image_path] ->
    #     Mix.Task.run("app.start")

    #     process_and_upload(image_path, opts)

    #   _ ->
    #     Mix.shell().error("Usage: mix blog_image path/to/image.jpg")
    #     exit({:shutdown, 1})
    # end
  end

  # defp process_and_upload(image_path, opts) do
  # quality = Keyword.get(opts, :quality, 85)
  # skip_upload = Keyword.get(opts, :skip_upload, false)
  # end

  # defp upload_to_r2(local_path, r2_key) do end

  # defp r2_config do end
end
