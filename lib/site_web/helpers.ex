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
    |> String.trim()
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

  @doc """
  Converts the content of a slot to HTML. This is useful for cases where we want to
  render the content of a slot as HTML but is VERY HACKY and should be changed
  in the future if MDEx adds an API for this.
  """
  def slot_content_to_html!(slot_content) when is_list(slot_content) do
    slot_content
    |> Enum.flat_map(fn slot ->
      case slot.inner_block do
        %Phoenix.LiveView.Rendered{static: static} -> static
        other -> [to_string(other)]
      end
    end)
    |> Enum.join()
    |> MDEx.to_html!()
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

  def base_cdn_url do
    Application.get_env(:site, :cdn_url, "https://cdn.nuno.site")
  end

  def cdn_image_url(image_path) do
    image_path
    |> URI.parse()
    |> case do
      %URI{host: nil} ->
        path =
          image_path
          |> String.trim_leading("/")
          |> String.trim_leading("images/")

        "#{base_cdn_url()}/images/#{path}"

      _ ->
        image_path
    end
  end
end
