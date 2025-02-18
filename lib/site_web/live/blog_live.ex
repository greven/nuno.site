defmodule SiteWeb.BlogLive do
  @moduledoc false

  use SiteWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    Blog Live!
    """
  end
end
