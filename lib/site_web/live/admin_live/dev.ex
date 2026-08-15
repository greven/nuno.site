defmodule SiteWeb.AdminLive.Dev do
  @moduledoc """
  Admin page for development specific functionality.
  """

  use SiteWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
    >
      <Layouts.page_content class="flex flex-col gap-8">
        <div class="flex flex-col gap-2">
          <SiteWeb.SiteComponents.back_link navigate={~p"/admin"} />
          <.header tag="h1">
            Dev Dashboard
          </.header>
        </div>

        <div class="grid grid-cols-4 gap-4">
          <.card class="aspect-square" navigate={~p"/admin/dev/posts"}>
            <.diagonal_pattern class="opacity-80" use_transition={false} />
            <div class="flex-1 flex flex-col items-center justify-center gap-4">
              <.icon name="lucide-file-pen-line" class="size-12 text-secondary" />
              <div class="font-headings text-content-30">Manage Posts</div>
            </div>
          </.card>

          <.card class="aspect-square" navigate={~p"/admin/dev/photos"}>
            <.diagonal_pattern class="opacity-80" use_transition={false} />
            <div class="flex-1 flex flex-col items-center justify-center gap-4">
              <.icon name="lucide-image-up" class="size-12 text-secondary" />
              <div class="font-headings text-content-30">Upload Photos</div>
            </div>
          </.card>

          <.card class="aspect-square" navigate={~p"/admin/dev/photos/manage"}>
            <.diagonal_pattern class="opacity-80" use_transition={false} />
            <div class="flex-1 flex flex-col items-center justify-center gap-4">
              <.icon name="lucide-image-down" class="size-12 text-secondary" />
              <div class="font-headings text-content-30">Manage Photos</div>
            </div>
          </.card>
        </div>
      </Layouts.page_content>
    </Layouts.app>
    """
  end
end
