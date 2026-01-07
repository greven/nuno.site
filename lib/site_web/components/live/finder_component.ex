defmodule SiteWeb.FinderComponent do
  @moduledoc """
  A finder / command palette that provides search
  and navigation functionality to the website.

  Check the `SiteWeb.Finder` module for implementation details.
  """

  use SiteWeb, :live_component

  alias SiteWeb.Finder

  @impl true
  def render(assigns) do
    ~H"""
    <div id="finder-component" class="finder" phx-hook="Finder" data-mode="default">
      <.dialog
        id="finder-dialog"
        data-close={Finder.close()}
        class={[
          "opacity-0 transition ease-out duration-250",
          "backdrop:bg-transparent backdrop:opacity-0 backdrop:backdrop-blur-[2px] backdrop:transition-opacity backdrop:ease-out backdrop:duration-250",
          "open:opacity-100 open:backdrop:bg-neutral-900/60 open:backdrop:opacity-100"
        ]}
      >
        <div
          tabindex="0"
          class="fixed inset-0 w-screen p-0 sm:p-6 md:p-20 overflow-y-auto focus:outline-none"
          data-part="dialog-container"
        >
          <.finder_panel>
            <%!-- Search input --%>
            <.finder_search class="relative hidden md:flex" />

            <%!-- Commands --%>
            <.finder_commands class={[
              "max-h-100 scroll-py-1 overflow-y-auto focus:outline-none",
              "divide-y divide-neutral-500/10 dark:divide-white/5"
            ]}>
              <%!-- Theme switcher --%>
              <.finder_section :if={@show_theme_switcher} id="theme-section">
                <.finder_section_title>Theme</.finder_section_title>

                <.finder_items_list id="finder-theme-switcher">
                  <.finder_item
                    id="set_theme_light"
                    type="command"
                    icon="lucide-sun"
                    description="Set light theme"
                    data-section="theme"
                    phx-click={
                      JS.dispatch("phx:set-theme", detail: %{theme: "light"})
                      |> JS.exec("data-close", to: "#finder-dialog")
                    }
                  >
                    Light Mode
                    <.icon
                      name="lucide-check"
                      class="hidden size-4.5 ml-1.5 text-secondary [[data-theme-mode=user][data-theme=light]_&]:block"
                    />
                  </.finder_item>
                  <.finder_item
                    id="set_theme_dark"
                    type="command"
                    icon="lucide-moon"
                    description="Set dark theme"
                    data-section="theme"
                    phx-click={
                      JS.dispatch("phx:set-theme", detail: %{theme: "dark"})
                      |> JS.exec("data-close", to: "#finder-dialog")
                    }
                  >
                    Dark Mode
                    <.icon
                      name="lucide-check"
                      class="hidden size-4.5 ml-1.5 text-secondary [[data-theme-mode=user][data-theme=dark]_&]:block"
                    />
                  </.finder_item>
                  <.finder_item
                    id="set_theme_system"
                    type="command"
                    icon="lucide-monitor"
                    description="Follow system theme settings"
                    data-section="theme"
                    phx-click={
                      JS.dispatch("phx:set-theme", detail: %{theme: "system"})
                      |> JS.exec("data-close", to: "#finder-dialog")
                    }
                  >
                    System Mode
                    <.icon
                      name="lucide-check"
                      class="hidden size-4.5 ml-1.5 text-secondary in-data-[theme-mode=system]:block"
                    />
                  </.finder_item>
                </.finder_items_list>
              </.finder_section>

              <%!-- Commands --%>
              <.finder_section :for={section <- @commands} id={"#{section.id}-section"}>
                <.finder_section_title>{section.title}</.finder_section_title>

                <.finder_items_list id={"finder-#{section.id}"}>
                  <.finder_item
                    :for={{id, opts} <- section.commands}
                    id={id}
                    icon={opts[:icon]}
                    description={opts[:description]}
                    data-section={section.id}
                    phx-click={opts[:push] && Finder.exec(id) |> Finder.close()}
                  >
                    {opts[:name]}
                  </.finder_item>
                </.finder_items_list>
              </.finder_section>
            </.finder_commands>

            <%!-- Content search results --%>
            <div
              id="finder-search-results"
              class="max-h-100 scroll-py-1 overflow-y-auto"
              data-part="items-container"
              tabindex="-1"
              hidden
            >
              <ul id="finder-search-items" class="p-2 text-sm"></ul>
            </div>

            <%!-- No results --%>
            <.finder_no_results>
              <:title>No results found.</:title>
              <:description>
                We couldn't find anything with that term. Please try again.
              </:description>
            </.finder_no_results>

            <%!-- Footer --%>
            <.finder_footer class="hidden md:flex justify-between bg-surface-30/40 px-4 py-2.5 text-xs text-content-40">
              <div class="flex items-center gap-8">
                <div class="flex flex-wrap items-center gap-2">
                  <.kbd><.icon name="hero-arrow-up" class="size-3" /></.kbd>
                  <.kbd><.icon name="hero-arrow-down" class="size-3" /></.kbd>
                  Move
                </div>

                <div class="flex flex-wrap items-center">
                  <.kbd class={[
                    "mx-2 sm:mx-2 px-1",
                    "in-data-[mode=search]:bg-secondary/5 in-data-[mode=search]:border-secondary in-data-[mode=search]:text-secondary"
                  ]}>
                    &gt;
                  </.kbd>
                  Search
                </div>
              </div>

              <div class="flex flex-wrap items-center">
                <.kbd class="mx-2 sm:mx-2 px-1">esc</.kbd>
                Clear <span class="ml-3 mr-1 text-content-40/30">|</span>
                <.kbd class="mx-2 sm:mx-2 px-1">
                  <.icon name="lucide-corner-down-left" class="size-3" />
                </.kbd>
                Select
              </div>
            </.finder_footer>
          </.finder_panel>
        </div>
      </.dialog>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:commands, Finder.list_commands())
      |> assign_new(:show_theme_switcher, fn -> true end)

    {:ok, socket}
  end

  @impl true
  def handle_event("finder:exec", %{"command_id" => id}, socket) do
    socket =
      String.to_existing_atom(id)
      |> Finder.handle_command(socket)

    {:noreply, socket}
  end

  def handle_event("finder:navigate", %{"id" => id}, socket) do
    post = Site.Blog.get_post_by_id!(id)
    {:noreply, push_navigate(socket, to: ~p"/blog/#{post.year}/#{post}")}
  end

  def handle_event("finder:update_search", _payload, socket) do
    articles_data = Site.Blog.list_articles_for_search()

    {:reply, %{status: "ok", data: articles_data}, socket}
  end

  def handle_event("finder:" <> _event, _params, socket), do: {:noreply, socket}

  ## Components

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  defp finder_panel(assigns) do
    ~H"""
    <div
      class={[
        "fixed -bottom-px left-1 right-1 md:max-w-xl md:relative md:mx-auto rounded-t-md md:rounded-md bg-surface-10/95 shadow-2xl overflow-hidden",
        "animate-slide-out-down data-open:animate-slide-in-up md:animate-none md:data-open:animate-none",
        "outline-1 outline-black/5 backdrop-blur-md backdrop-filter",
        "divide-y divide-neutral-500/10 dark:divide-white/5",
        "dark:-outline-offset-1 dark:outline-white/10",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :id, :string, default: "finder-commands"
  attr :class, :any, default: nil
  slot :inner_block, required: true

  defp finder_commands(assigns) do
    ~H"""
    <div
      id={@id}
      class={@class}
      data-part="items-container"
      tabindex="-1"
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string,
    default: "hidden sm:flex justify-between bg-surface-30/40 px-4 py-2.5 text-xs text-content-40"

  attr :rest, :global
  slot :inner_block, required: true

  defp finder_footer(assigns) do
    ~H"""
    <div class={@class} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :id, :string, default: "finder-input"
  attr :placeholder, :string, default: "Search or type a command..."
  attr :rest, :global

  defp finder_search(assigns) do
    ~H"""
    <div {@rest}>
      <.icon
        name="hero-magnifying-glass-mini"
        class="absolute left-4 top-3.5 h-5 w-5 text-content-40 pointer-events-none"
      />
      <input
        id={@id}
        class="w-full h-12 pl-11 px-4 py-2.5 rounded-md bg-transparent border-0 placeholder:text-content-40/80 text-content-10 sm:text-sm focus:outline-none focus:ring-0"
        placeholder={@placeholder}
        autocomplete="off"
        role="combobox"
        aria-expanded="false"
        aria-controls="options"
        autofocus
      />
    </div>
    """
  end

  attr :id, :string, default: "finder-no-results"
  attr :icon, :string, default: "lucide-radar"
  attr :rest, :global

  slot :title
  slot :description

  defp finder_no_results(assigns) do
    ~H"""
    <div id={@id} class="px-6 py-14 text-center text-sm sm:px-14" hidden>
      <.icon name={@icon} class="mx-auto mb-4 size-8 text-content-40/40" />
      <%= if @title != [] do %>
        <p class="text-content-40/80">{render_slot(@title)}</p>
      <% else %>
        <p class="text-content-40/80">No results.</p>
      <% end %>
      <p :if={@description != []} class="mt-2 text-content-30">
        {render_slot(@description)}
      </p>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :rest, :global
  slot :inner_block, required: true

  defp finder_section(assigns) do
    ~H"""
    <section id={@id} {@rest}>
      {render_slot(@inner_block)}
    </section>
    """
  end

  attr :class, :any, default: nil
  slot :inner_block, required: true

  defp finder_section_title(assigns) do
    ~H"""
    <h3 class={["mt-4 mb-0.5 px-5 font-headings text-xs text-content-40/80", @class]}>
      {render_slot(@inner_block)}
    </h3>
    """
  end

  attr :id, :string, required: true
  attr :class, :any, default: nil
  slot :inner_block, required: true

  defp finder_items_list(assigns) do
    ~H"""
    <ul id={@id} class={["p-2 text-sm", @class]}>
      {render_slot(@inner_block)}
    </ul>
    """
  end

  attr :id, :string, required: true
  attr :class, :string, default: nil
  attr :description, :string, default: nil
  attr :selected, :boolean, default: false
  attr :icon, :string, default: nil
  attr :type, :string, values: ["command", "nav"], default: "nav"

  attr :icon_class, :string,
    default: "size-5 flex-none text-content-40/60 group-aria-selected:text-secondary"

  attr :rest, :global

  slot :inner_block, required: true

  defp finder_item(assigns) do
    ~H"""
    <li
      id={@id}
      class={[
        "group cursor-default flex items-center justify-between rounded-md px-3 py-2 select-none",
        "aria-selected:bg-neutral-900/5 dark:aria-selected:bg-neutral-50/4",
        "focus:outline-hidden",
        @class
      ]}
      role="option"
      tabindex="-1"
      data-type="command"
      aria-selected="false"
      data-description={@description}
      {@rest}
    >
      <div class="flex items-center">
        <.icon :if={@icon} name={@icon} class={@icon_class} />
        <span
          class="ml-3 flex items-center flex-none text-xs text-content-30 group-aria-selected:text-content-10"
          data-slot="text"
        >
          {render_slot(@inner_block)}
        </span>
      </div>

      <.icon
        :if={@type == "nav"}
        name="hero-chevron-right"
        class="md:hidden size-4 flex-none text-secondary/90"
      />
    </li>
    """
  end
end
