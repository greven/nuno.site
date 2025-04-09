defmodule SiteWeb.BlogLive do
  @moduledoc false

  use SiteWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_link={@active_link}>
      Blog Live!
    </Layouts.app>
    """
  end
end
