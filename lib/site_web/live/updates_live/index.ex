defmodule SiteWeb.UpdatesLive.Index do
  use SiteWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
    >
      <Layouts.page_content class="flex flex-col gap-12 md:gap-16">
        <.header>
          Recent Updates
          <:subtitle>
            Latest updates from me, articles, social media, etc.
          </:subtitle>
        </.header>
      </Layouts.page_content>
    </Layouts.app>
    """
  end
end
