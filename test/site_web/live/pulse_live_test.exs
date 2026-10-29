defmodule SiteWeb.PulseLiveTest do
  use SiteWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Phoenix.LiveView.AsyncResult
  alias Site.Pulse.Item
  alias SiteWeb.PulseLive.Components

  describe "news source failures" do
    test "renders the failed state without crashing" do
      async = AsyncResult.failed(AsyncResult.loading(), :source_down)

      html =
        render_component(&Components.news_source/1,
          source: :bbc,
          async: async,
          news: []
        )

      assert html =~ "BBC News"
      assert html =~ "Failed to load source."
    end
  end

  describe "news feed detail items" do
    test "renders an item with a missing date and unknown source" do
      item = %Item{
        id: "item-1",
        source: :removed_source,
        url: "https://example.com/article",
        title: "An article",
        date: nil
      }

      html =
        render_component(&Components.news_feed_detail_item/1,
          id: "item-1-detail",
          item: item
        )

      assert html =~ "Unknown source"
      assert html =~ "An article"
      assert html =~ "date unavailable"
    end

    test "renders a valid item date" do
      item = %Item{
        id: "item-2",
        source: :bbc,
        url: "https://example.com/article",
        title: "Another article",
        date: ~U[2026-10-29 12:00:00Z]
      }

      html =
        render_component(&Components.news_feed_detail_item/1,
          id: "item-2-detail",
          item: item
        )

      assert html =~ "BBC News"
      assert html =~ "Another article"
      assert html =~ "Published"
      refute html =~ "date unavailable"
    end
  end

  describe "forex failures" do
    test "renders partial rates and missing changes" do
      forex = %{
        current: %{
          date: nil,
          rates: %{
            gbp: nil,
            usd: Decimal.new("1.2"),
            jpy: Decimal.new("150"),
            chf: Decimal.new("0.9")
          }
        },
        change: %{gbp: nil}
      }

      html = render_component(&Components.forex/1, forex: forex)

      assert html =~ "Forex"
      assert html =~ "Unknown"
      assert html =~ "0.0%"
    end

    test "renders the unavailable state for malformed data" do
      html = render_component(&Components.forex/1, forex: %{current: nil})

      assert html =~ "Exchange rates are currently unavailable."
    end

    test "renders the unavailable state for nil data" do
      html = render_component(&Components.forex/1, forex: nil)

      assert html =~ "Exchange rates are currently unavailable."
    end
  end

  describe "weather failures" do
    test "renders the weather card in the failed state" do
      async = AsyncResult.failed(AsyncResult.loading(), :weather_down)

      html = render_component(&Components.weather/1, weather: async)

      assert html =~ "Failed to load weather!"
    end

    test "renders an empty forecast list without crashing" do
      html =
        render_component(&Components.weather_forecast_list/1,
          weather: AsyncResult.ok(%{daily: []}),
          number_of_days: 5
        )

      assert html =~ "w-full"
    end
  end
end
