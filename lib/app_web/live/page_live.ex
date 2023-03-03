defmodule AppWeb.PageLive do
  use AppWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    Homepage! <br />
    <.link class="underline text-primary" navigate={~p"/blog"}>Blog</.link>
    <.link class="underline text-primary" navigate={~p"/stats"}>Stats</.link>
    """
  end
end
