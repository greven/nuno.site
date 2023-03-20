defmodule AppWeb.LiveComponents.FinderComponent do
  @moduledoc """
  A finder / command palette that provides search and navigation
  functionality to the website.
  """

  use AppWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="finder-component__body">
      <.icon
        name="hero-magnifying-glass-mini"
        class="w-5 h-5 text-secondary-500 hover:text-secondary-700 hover:cursor-pointer"
      />
    </div>
    """
  end
end
