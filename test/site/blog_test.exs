defmodule Site.BlogTest do
  use ExUnit.Case

  alias Site.Blog.Parser
  alias Site.Blog.HeaderLink

  describe "parse_headers/1" do
    test "Parse header links when present" do
      content = """
      # Title
      The title should be not be included

      ## Section Title
      Lorem ipsum?

      ### SubSection Title
      Toodly Doodly Doo!

      ## Childless Section
      Just some plain text.

      ## Last Section

      ### Last Section SubSection
      Last action hero!

      #### Last Section SubSection SubSection
      H4, how bold!
      """

      expected = [
        %HeaderLink{
          depth: 1,
          id: "section-title",
          subsections: [
            %HeaderLink{
              depth: 2,
              id: "subsection-title",
              subsections: [],
              text: "SubSection Title"
            }
          ],
          text: "Section Title"
        },
        %HeaderLink{
          depth: 1,
          id: "childless-section",
          subsections: [],
          text: "Childless Section"
        },
        %HeaderLink{
          depth: 1,
          id: "last-section",
          subsections: [
            %HeaderLink{
              id: "last-section-subsection",
              text: "Last Section SubSection",
              depth: 2,
              subsections: [
                %HeaderLink{
                  id: "last-section-subsection-subsection",
                  text: "Last Section SubSection SubSection",
                  depth: 3,
                  subsections: []
                }
              ]
            }
          ],
          text: "Last Section"
        }
      ]

      options = [
        render: [
          unsafe: true,
          escape: false
        ]
      ]

      headings =
        content
        |> MDEx.parse_document!(options)
        |> Parser.linkify_headers()
        |> MDEx.to_html!(options)
        |> Parser.parse_headers()

      assert headings == expected
    end
  end
end
