defmodule SiteWeb.SiteComponentsTest do
  use SiteWeb.ConnCase

  import Phoenix.LiveViewTest

  alias SiteWeb.SiteComponents

  describe "pagination/1" do
    test "renders the pages around the current page plus the first and last pages" do
      html =
        render_component(&SiteComponents.pagination/1,
          page: 5,
          total_pages: 12,
          event: "paginate_books"
        )

      document = LazyHTML.from_fragment(html)

      assert Enum.count(document["nav[aria-label='Pagination']"]) == 1
      assert Enum.count(document["button[aria-label='Previous page']"]) == 1
      assert Enum.count(document["button[aria-label='Next page']"]) == 1

      assert Enum.map(document["button[aria-label^='Page ']"], &page_label/1) ==
               ["1", "4", "5", "6", "12"]

      assert Enum.count(document["nav[aria-label='Pagination'] > span[aria-hidden='true']"]) == 2
    end

    test "sends the configured event with the clicked page" do
      html =
        render_component(&SiteComponents.pagination/1,
          page: 5,
          total_pages: 12,
          event: "paginate_books"
        )

      document = LazyHTML.from_fragment(html)
      current_page = document["button[aria-label='Page 5']"]

      assert LazyHTML.attribute(current_page, "aria-current") == ["page"]
      assert LazyHTML.attribute(current_page, "phx-click") == ["paginate_books"]
      assert LazyHTML.attribute(current_page, "phx-value-page") == ["5"]
    end

    test "disables previous on the first page and next on the last page" do
      first_page =
        LazyHTML.from_fragment(
          render_component(&SiteComponents.pagination/1, page: 1, total_pages: 3)
        )

      last_page =
        LazyHTML.from_fragment(
          render_component(&SiteComponents.pagination/1, page: 3, total_pages: 3)
        )

      assert LazyHTML.attribute(first_page["button[aria-label='Previous page']"], "disabled") ==
               [""]

      assert LazyHTML.attribute(first_page["button[aria-label='Next page']"], "disabled") == []

      assert LazyHTML.attribute(last_page["button[aria-label='Previous page']"], "disabled") == []

      assert LazyHTML.attribute(last_page["button[aria-label='Next page']"], "disabled") == [""]
    end

    test "renders every page when there are few" do
      html = render_component(&SiteComponents.pagination/1, page: 2, total_pages: 5)
      document = LazyHTML.from_fragment(html)

      assert Enum.map(document["button[aria-label^='Page ']"], &page_label/1) ==
               ["1", "2", "3", "4", "5"]
    end

    test "renders nothing for a single page" do
      html = render_component(&SiteComponents.pagination/1, page: 1, total_pages: 1)

      refute html =~ "Pagination"
    end
  end

  defp page_label(button), do: button |> LazyHTML.text() |> String.trim()
end
