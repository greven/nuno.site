defmodule SiteWeb.OpenGraph do
  @moduledoc """
  OpenGraph images generation using Typst.
  """

  @fallback_filename "open-graph.png"

  def fallback_assigns do
    [
      title: "Nuno's Site",
      subtitle: "Software Engineer · Blog",
      is_fallback: true
    ]
  end

  def fallback_image_path, do: Path.join([static_dir(), "images", @fallback_filename])
  defp static_dir, do: Application.app_dir(:site, "priv/static")
  # Typst template for blog posts
  def post_template do
    """
    #set page(
      width: 1200pt,
      height: 630pt,
      margin: 36pt,
      background: image("/images/bg.png", width: 100%, height: 100%, fit: "cover"),
      fill: none
    )

    #set text(
      font: "Inter",
      fill: rgb("#3a3a3c")
    )

    #v(164pt)

    #align(center)[
    // Article Tag
    #box[
      #set text(size: 22pt, weight: "regular")
      #box(fill: rgb("#77777710"), stroke: (paint: rgb("#777777"), thickness: 1pt), inset: (x: 10pt, y: 6pt))[
        #upper[#text(fill: rgb("#777777"), "Article")]
      ]
      #h(16pt)
    ]
    // Tags section
      #if <%= Enum.count(tags) %> > 0 [
        #box[
          #set text(size: 22pt, weight: "regular")
          <%= for tag <- tags do %>#box(fill: rgb("#CE434610"), stroke: (paint: rgb("#CE4346"), thickness: 1pt), inset: (x: 10pt, y: 6pt))[
            #upper[#text(fill: rgb("#CE4346"), "#<%= tag %>")]
          ]
          #h(12pt)
          <% end %>
        ]
      ]
    ]

    #v(16pt)

    // Title - Large, bold, Space Grotesk
    #align(center)[
      #block(width: 900pt)[
        #underline(offset: 8pt, stroke: (paint: rgb("#333333"), thickness: 2pt), evade: true)[
          #text(
            font: "Space Grotesk",
            size: 74pt,
            weight: "medium",
            fill: rgb("#eeeeee")
          )[<%= title %>]
        ]
      ]
    ]

    #v(32pt)

    // Footer - Reading time
    #place(bottom + right)[
      #text(size: 24pt, weight: "regular", fill: rgb("#777777"))[<%= reading_time %>]
    ]
    """
  end
end
