defmodule Site.Services.GoodreadsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Site.Services.Book
  alias Site.Services.Goodreads

  @fixture Path.expand("fixtures/goodreads_profile.html", __DIR__)

  setup do
    Req.Test.set_req_test_to_shared()
    Site.Cache.delete(:goodreads_profile_html)
    :ok
  end

  describe "parse_profile/1" do
    test "extracts shelf counts and currently reading books" do
      assert {:ok, %{stats: stats, books: books}} =
               Goodreads.parse_profile(File.read!(@fixture))

      assert stats == %{currently_reading: 3, total_read: 108}
      assert length(books) == 3

      assert %Book{
               id: "24963100",
               title: "The Amber Spyglass (His Dark Materials, #3)",
               author: "Philip Pullman",
               url: "https://www.goodreads.com/book/show/24963100-the-amber-spyglass",
               cover_url:
                 "https://i.gr-assets.com/images/S/compressed.photo.goodreads.com/books/1424331573l/24963100._SY475_.jpg",
               thumbnail_url:
                 "https://i.gr-assets.com/images/S/compressed.photo.goodreads.com/books/1424331573l/24963100._SX98_.jpg"
             } = hd(books)
    end

    test "returns a parse error when the page structure is unknown" do
      assert {:error, :parse_error} = Goodreads.parse_profile("<html></html>")
    end
  end

  describe "get_reading_stats/0" do
    test "returns an error when the profile request fails" do
      Req.Test.stub(Goodreads, fn conn ->
        Plug.Conn.send_resp(conn, 404, "page not found")
      end)

      capture_log(fn ->
        assert {:error, _reason} = Goodreads.get_reading_stats()
      end)
    end

    test "falls back to the last cached profile when the request fails" do
      Site.Cache.put(:goodreads_profile_html, File.read!(@fixture), ttl: :timer.minutes(30))

      Req.Test.stub(Goodreads, fn conn ->
        Plug.Conn.send_resp(conn, 404, "page not found")
      end)

      capture_log(fn ->
        assert {:ok, %{currently_reading: 3, total_read: 108}} =
                 Goodreads.get_reading_stats()
      end)
    end
  end
end
