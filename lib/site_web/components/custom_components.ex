defmodule SiteWeb.CustomComponents do
  @moduledoc """
  Custom components for the site.
  """

  use SiteWeb, :html

  @doc false

  attr :class, :string, default: nil

  def avatar_picture(assigns) do
    ~H"""
    <div class="h-10 w-10 rounded-full bg-white/90 p-0.5 shadow-md shadow-neutral-800/5
        ring-1 ring-neutral-900/5 backdrop-blur dark:bg-neutral-800/90 dark:ring-white/10">
      <.link navigate={~p"/"} aria-label="Home" class="pointer-events-auto">
        <.image
          src="/images/avatar.png"
          alt="avatar"
          height={40}
          width={40}
          class={[@class, "rounded-full bg-neutral-100 object-cover dark:bg-neutral-800"]}
        />
      </.link>
    </div>
    """
  end
end
