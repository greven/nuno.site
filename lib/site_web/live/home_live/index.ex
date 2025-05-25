defmodule SiteWeb.HomeLive.Index do
  use SiteWeb, :live_view

  alias SiteWeb.SiteComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_link={@active_link}>
      <div class="container mx-auto px-4 py-8">
        <h1 class="text-4xl font-bold mb-12 text-center text-gray-800 dark:text-white">
          Welcome to my Website!
        </h1>

        <SiteComponents.bento_grid>
          <SiteComponents.bento_box navigate={~p"/about"}>
            About
          </SiteComponents.bento_box>

          <SiteComponents.bento_box navigate={~p"/articles"}>
            Articles
          </SiteComponents.bento_box>

          <SiteComponents.bento_box navigate={~p"/travel"}>
            Travel
          </SiteComponents.bento_box>
        </SiteComponents.bento_grid>
      </div>
    </Layouts.app>
    """
  end
end
