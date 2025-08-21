defmodule SiteWeb.BooksLive.Index do
  use SiteWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_link={@active_link}>
      <Layouts.page_content class="flex flex-col gap-16">
        <h2 class="text-3xl font-semibold">🚧 Work in Progress 🚧</h2>
      </Layouts.page_content>
    </Layouts.app>
    """
  end
end
