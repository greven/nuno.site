defmodule SiteWeb.LiveComponents do
  @moduledoc """
  Group LiveComponents and wrap them in functional components for easier use.
  """

  use SiteWeb, :html

  @doc false

  attr :id, :string, required: true

  def finder(assigns) do
    ~H"""
    <.live_component id={@id} module={SiteWeb.FinderComponent} />
    """
  end

  @doc false

  attr :id, :string, required: true
  attr :class, :string, default: "w-full md:w-3xs"
  attr :href, :string, required: true
  attr :text, :string
  attr :rest, :global, include: ~w(download hreflang referrerpolicy rel target type)

  def live_preview(assigns) do
    assigns = assign_new(assigns, :text, fn -> nil end)

    ~H"""
    <.live_component
      id={@id}
      module={SiteWeb.LinkPreviewComponent}
      href={@href}
      text={@text}
      rest={@rest}
      class={@class}
    />
    """
  end
end
