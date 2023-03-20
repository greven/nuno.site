defmodule AppWeb.PageComponents do
  @moduledoc """
  Page components and helpers.
  """

  use Phoenix.Component
  use AppWeb, :verified_routes

  attr :class, :string, default: nil
  attr :post, :any, required: true

  def avatar_picture(assigns) do
    ~H"""
    <div class="h-10 w-10 rounded-full bg-white/90 p-0.5 shadow-md shadow-zinc-800/5 ring-1 ring-zinc-900/5 backdrop-blur dark:bg-zinc-800/90 dark:ring-white/10">
      <.link navigate={~p"/"} aria-label="Home" class="pointer-events-auto">
        <img
          src="/images/avatar.png"
          alt="avatar"
          class={[@class, "rounded-full bg-zinc-100 object-cover dark:bg-zinc-800 h-9 w-9"]}
        />
      </.link>
    </div>
    """
  end
end
