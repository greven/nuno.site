defmodule SiteWeb.HomeLive.Index do
  use SiteWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_link={@active_link}>
      Home!
    </Layouts.app>
    """
  end
end
