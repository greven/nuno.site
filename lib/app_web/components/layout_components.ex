defmodule AppWeb.LayoutComponents do
  @moduledoc """
  Layout components.
  """

  use Phoenix.Component
  use AppWeb, :verified_routes

  def navbar(assigns) do
    ~H"""
    <nav class="bg-transparent">
      <div class="mx-auto max-w-7xl px-2 sm:px-6 lg:px-8">
        <div class="relative flex h-16 items-center justify-between">
          <div class="flex items-center justify-center gap-3.5">
            <svg height="22" viewBox="0 0 20 20" fill="currentColor">
              <path d="M6.023 7.296v5.419H3.648C1.644 12.715 0 14.316 0 16.342 0 18.355 1.644 20 3.648 20a3.657 3.657 0 003.648-3.659v-2.375h5.397v2.376A3.657 3.657 0 0016.343 20c2.004 0 3.647-1.644 3.647-3.659 0-2.025-1.643-3.626-3.648-3.626h-2.375v-5.42h2.376c2.004 0 3.647-1.611 3.647-3.626C19.99 1.644 18.346 0 16.341 0c-2.014 0-3.648 1.644-3.648 3.67v2.364H7.296V3.669C7.296 1.644 5.663 0 3.648 0 1.644 0 0 1.644 0 3.67c0 2.014 1.644 3.626 3.648 3.626h2.375zm-2.375-1.24c-1.294 0-2.375-1.083-2.375-2.387 0-1.315 1.081-2.396 2.375-2.396 1.304 0 2.375 1.081 2.375 2.396v2.386H3.648zm12.694 0h-2.376V3.668c0-1.315 1.071-2.396 2.376-2.396 1.293 0 2.375 1.081 2.375 2.396 0 1.304-1.082 2.386-2.375 2.386zm-9.046 6.67V7.274h5.397v5.45H7.296zm-3.648 1.219h2.375v2.386a2.387 2.387 0 01-2.375 2.386 2.394 2.394 0 01-2.375-2.386 2.394 2.394 0 012.375-2.386zm12.694 0a2.394 2.394 0 012.375 2.386 2.394 2.394 0 01-2.375 2.386 2.387 2.387 0 01-2.376-2.386v-2.386h2.376z">
              </path>
            </svg>
            <h1 class="text-xl font-medium">
              <.link navigate={~p"/"}>
                nuno.fm
              </.link>
            </h1>
          </div>

          <div class="flex space-x-4">
            <.navbar_item title="About" navigate={~p"/about"} />
            <.navbar_item title="Writing" navigate={~p"/writing"} />
            <.navbar_item title="Stats" navigate={~p"/stats"} />
            <.navbar_item :if={@current_user} title="Admin" navigate={~p"/admin"} />
          </div>
        </div>
      </div>
    </nav>
    """
  end

  attr :title, :string, required: true
  attr :navigate, :string, required: true

  def navbar_item(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class="text-neutral-400 text-sm font-semibold uppercase transition-colors hover:text-neutral-800 hover:underline hover:underline-offset-8 hover:decoration-primary hover:decoration-2"
    >
      <%= @title %>
    </.link>
    """
  end
end
