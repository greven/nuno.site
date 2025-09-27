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
          text: "Section Title",
          subsections: [
            %HeaderLink{
              depth: 2,
              id: "subsection-title",
              text: "SubSection Title",
              subsections: []
            }
          ]
        }
      ]

      headings =
        content
        |> MDEx.to_html!()
        |> Parser.parse_headers()

      assert headings == expected
    end
  end

  # describe "get_next_and_prev_posts/1" do
  # test "given a post with existing previous and next posts return the corresponding posts" do
  # Blog.get_next_and_prev_posts()
  # end
  # end
end
