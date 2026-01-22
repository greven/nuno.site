defmodule SiteWeb.Helpers do
  @moduledoc """
  A collection of helper functions for use throughout the site.
  """

  # ------------------------------------------
  #  Utils
  # ------------------------------------------

  def use_id(prefix \\ "ns") do
    "#{prefix}-"
    |> Kernel.<>(random_encoded_bytes())
    |> String.replace(["/", "+"], "-")
  end

  # Taken from Phoenix LiveView
  defp random_encoded_bytes do
    binary = <<
      System.system_time(:nanosecond)::64,
      :erlang.phash2({node(), self()})::16,
      :erlang.unique_integer()::16
    >>

    Base.url_encode64(binary)
  end

  # ------------------------------------------
  #  Markdown
  # ------------------------------------------

  def render_markdown!(text) do
    text
    |> MDEx.to_html!()
    |> Phoenix.HTML.raw()
  end

  # ------------------------------------------
  #  Dates
  # ------------------------------------------

  def format_date(date, format)

  def format_date(nil, _), do: nil

  def format_date(%Date{} = date, format) do
    Calendar.strftime(date, format)
  end

  # ------------------------------------------
  #  CDN
  # ------------------------------------------

  def cdn_image_url(image_path) do
    cdn_base_url = Application.get_env(:site, :cdn_url, "https://cdn.nuno.site")

    image_path
    |> URI.parse()
    |> case do
      %URI{host: nil} ->
        path =
          image_path
          |> String.trim_leading("/")
          |> String.trim_leading("images/")

        "#{cdn_base_url}/images/#{path}"

      _ ->
        image_path
    end
  end
end
