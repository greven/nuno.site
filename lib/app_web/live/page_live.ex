defmodule AppWeb.PageLive do
  use AppWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <ul class="">
      <li>
        <.link class="underline text-primary" navigate={~p"/blog"}>Blog</.link>
      </li>
      <li>
        <.link class="underline text-primary" navigate={~p"/admin"}>Admin</.link>
      </li>
      <li>
        <.link class="underline text-primary" navigate={~p"/stats"}>Stats</.link>
      </li>
    </ul>
    """
  end
end
