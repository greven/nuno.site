defmodule AppWeb.AdminPostsLive do
  use AppWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <%!-- Index --%>
    <div :if={@live_action == :index}>
      Posts List
    </div>

    <%!-- Index --%>
    <div :if={@live_action == :index}>
      Posts List
    </div>
    """
  end
end
