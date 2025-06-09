defmodule SiteWeb.HomeLive.Index do
  use SiteWeb, :live_view

  alias SiteWeb.SiteComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_link={@active_link}>
      <Layouts.page_content>
        <div class="container mx-auto px-4 py-8">
          <h1 class="text-4xl font-light text-center text-gray-800 dark:text-white">
            Welcome to my Website!
          </h1>

          <SiteComponents.bento_grid class="mt-12">
            <.card navigate={~p"/about"}>
              About
            </.card>

            <.card navigate={~p"/articles"}>
              Articles
            </.card>

            <.card navigate={~p"/travel"}>
              Travel
            </.card>
          </SiteComponents.bento_grid>

          <div class="mt-16">
            <.button phx-click={show_dialog("#basic-dialog")}>Open Dialog</.button>

            <.dialog :let={cancel} id="basic-dialog">
              This is a simple dialog with some content.
              <.button phx-click={cancel}>Close</.button>
            </.dialog>
          </div>

          <div class="mt-16">
            <.button phx-click={show_dialog("#fancy-modal")}>Open Modal</.button>

            <.modal id="fancy-modal">
              <:title>This is a fancy modal title!</:title>
            </.modal>
          </div>
        </div>
      </Layouts.page_content>
    </Layouts.app>
    """
  end
end
