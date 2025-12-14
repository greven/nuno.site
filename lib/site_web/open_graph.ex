defmodule SiteWeb.OpenGraph do
  @moduledoc """
  OpenGraph images generation using Typst.
  """

  @fallback_filename "og-fallback.png"

  def fallback_assigns do
    [
      title: "Nuno's Site",
      subtitle: "Software Engineer · Blog",
      is_fallback: true
    ]
  end

  def generate_fallback_image() do
    image_path = fallback_image_path()
    template = fallback_template()
    assigns = fallback_assigns()

    Ogi.render_to_png(@fallback_filename, template, assigns)
    |> case do
      {:ok, image} -> File.write(image_path, image)
      {:error, reason} -> {:error, reason}
    end
  end

  def fallback_image_path, do: Path.join([static_dir(), "images", @fallback_filename])
  defp static_dir, do: Application.app_dir(:site, "priv/static")

  # Typst template for blog posts
  def post_template do
    """
    #set page(
      width: 1200pt,
      height: 630pt,
      margin: 64pt,
      fill: rgb("#0d0d0d")
    )

    #set text(
      font: "Inter",
      fill: rgb("#3a3a3c")
    )

    // Diagonal pattern background - positioned absolutely at page corner
    #place(
      top + right,
      dx: 64pt,
      dy: -64pt
    )[
      #box(
        width: 600pt,
        height: 630pt,
        clip: true
      )[
        #for i in range(0, 60) [
          #place(
            top + left,
            dx: i * 10pt,
            dy: -200pt
          )[
            #rotate(45deg)[
              #line(
                length: 1200pt,
                stroke: (
                  paint: rgb("#e1d8da14"),
                  thickness: 1.5pt
                )
              )
            ]
          ]
        ]
      ]
    ]

    // Title - Large, bold, Montserrat
    #block[
      #text(
        font: "Montserrat",
        size: 64pt,
        weight: "bold",
        fill: rgb("#e1d8da")
      )[<%= title %>]
    ]

    #v(32pt)

    // Decorative accent line
    #box(
      width: 80pt,
      height: 4pt,
      fill: rgb("#cd4346")
    )

    #v(32pt)

    // Tags section - horizontal layout with hashtags
    #if <%= Enum.count(tags) %> > 0 [
      #box[
        #set text(size: 28pt, weight: "medium")
        <%= for tag <- tags do %>#text(fill: rgb("#6b7280"), "\#")#text(fill: rgb("#d1d5db"), "<%= tag %>")#h(20pt)<% end %>
      ]
      
      #v(24pt)
    ]

    // Footer - Site logo and reading time
    #place(bottom + left)[
      #text(size: 26pt, weight: "medium", font: "Montserrat")[
        #text(fill: rgb("#e1d8da"), "nuno")#h(-2pt)
        #text(fill: rgb("#9ca3af"), ".")#h(-2pt)
        #text(fill: rgb("#d1d5db"), "site")#h(-3pt)
        #text(fill: rgb("#cd4346"), font: "Courier New", "_")
      ]
    ]

    #place(bottom + right)[
      #text(size: 26pt, weight: "regular", fill: rgb("#6b7280"))[<%= reading_time %>]
    ]
    """
  end

  # Typst template for fallback image
  def fallback_template do
    """
    #set page(
      width: 1200pt,
      height: 630pt,
      margin: 64pt,
      fill: rgb("#0d0d0d")
    )

    #set text(
      font: "Inter",
      fill: rgb("#3a3a3c")
    )

    // Diagonal pattern background - positioned absolutely at page corner
    #place(
      top + right,
      dx: 64pt,
      dy: -64pt
    )[
      #box(
        width: 600pt,
        height: 630pt,
        clip: true
      )[
        #for i in range(0, 60) [
          #place(
            top + left,
            dx: i * 10pt,
            dy: -200pt
          )[
            #rotate(45deg)[
              #line(
                length: 1200pt,
                stroke: (
                  paint: rgb("#e1d8da14"),
                  thickness: 1.5pt
                )
              )
            ]
          ]
        ]
      ]
    ]

    // Title - Large, bold, Montserrat
    #block[
      #text(
        font: "Montserrat",
        size: 64pt,
        weight: "bold",
        fill: rgb("#e1d8da")
      )[<%= title %>]
    ]

    #v(32pt)

    // Decorative accent line
    #box(
      width: 80pt,
      height: 4pt,
      fill: rgb("#cd4346")
    )

    #v(32pt)

    // Subtitle
    #text(
      size: 28pt,
      weight: "regular",
      fill: rgb("#6b7280")
    )[<%= subtitle %>]

    // Footer - Site logo
    #place(bottom + left)[
      #text(size: 26pt, weight: "medium", font: "Montserrat")[
        #text(fill: rgb("#e1d8da"), "nuno")#h(-2pt)
        #text(fill: rgb("#9ca3af"), ".")#h(-2pt)
        #text(fill: rgb("#d1d5db"), "site")#h(-3pt)
        #text(fill: rgb("#cd4346"), font: "Courier New", "_")
      ]
    ]
    """
  end
end
