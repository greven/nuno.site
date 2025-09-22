defmodule SiteWeb.HomeLive.Index do
  use SiteWeb, :live_view

  alias Site.Blog
  alias Site.Services
  alias Site.Services.MusicTrack

  alias SiteWeb.SiteComponents
  alias SiteWeb.HomeLive.Components

  @refresh_interval 10_000

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
      is_home
    >
      <Layouts.page_content class="flex flex-col gap-16">
        <section id="hero">
          <.link
            href="/about"
            id="hello"
            phx-hook="Hello"
            class="inline-block text-center md:text-left"
          >
            <div class="w-fit mb-2 md:mb-0">
              <div
                id="hello-text"
                class="relative inline-block px-1.5 py-0.5 text-base md:text-2xl bg-content/4 rounded-xs opacity-0"
              >
                <div
                  id="hello-content"
                  class="motion-safe:animate-[glitch_4s_ease-in-out]"
                  title="Yes, this is a Mr Robot reference!"
                >
                  <span
                    class="text-neutral-500 hover:text-neutral-600 transition-colors dark:text-neutral-400 hover:dark:text-neutral-300"
                    data-text="h3ll0, fr13nd!"
                  >
                  </span>
                  <span class="font-mono text-primary motion-safe:animate-blink">_</span>
                </div>
              </div>
            </div>
          </.link>

          <div id="site-intro" class="text-center md:text-left">
            <h1 class="flex flex-col font-headings leading-tight">
              <div class="-ml-1 md:-ml-2 text-7xl md:text-9xl tracking-tight">
                I'm
                <strong class="contrast-125 font-semibold">Nuno</strong><span class="text-primary">.</span>
              </div>
            </h1>

            <div class="text-md md:text-2xl text-content-40">
              A <.link href="/about" class="link">Software Engineer</.link> from Lisbon.
            </div>

            <p class="mt-8 max-w-3xl font-light text-base/7 md:text-xl/8 text-content-30 text-balance">
              This site is where I share my knowledge and ideas with others. Here you'll find a
              <.link href="/updates" class="link-subtle">collection</.link>
              of my <.link href="/articles?category=blog" class="link-subtle">articles</.link>, <.link
                href="/articles?category=note"
                class="link-subtle"
              >notes</.link>, and experiments.
            </p>
          </div>
        </section>

        <%!-- Bento Grid --%>
        <div class="flex flex-col gap-28 last:mb-16">
          <div
            id="bento-grid"
            class="relative grid grid-cols-2 md:grid-cols-4 auto-rows-[minmax(0,4fr)] gap-4 scroll-my-24"
          >
            <SiteComponents.bento_card
              navigate={~p"/articles"}
              class="col-span-1 row-span-1 aspect-square"
              icon="lucide-file-text"
            >
              <div class="flex flex-col text-sm md:text-base">
                <div class="text-content-40">Blog</div>
                <div class="font-medium">
                  {"#{@post_count} #{ngettext("Article", "Articles", @post_count)}"}
                </div>
              </div>
            </SiteComponents.bento_card>

            <SiteComponents.bento_card
              navigate={~p"/music"}
              class="col-span-1 row-span-1"
              icon="lucide-music"
            >
              <Components.now_playing track={@track} />
            </SiteComponents.bento_card>

            <SiteComponents.bento_card
              navigate={~p"/books"}
              class="col-span-1 row-span-1"
              icon="lucide-library"
            >
              <div class="flex flex-col text-sm md:text-base">
                <div class="text-content-40">Reading</div>
                <div class="font-medium">
                  {"#{@reading_count} #{ngettext("Book", "Books", @reading_count)}"}
                </div>
              </div>
            </SiteComponents.bento_card>

            <%!-- <SiteComponents.bento_card
              navigate={~p"/travel"}
              class="col-span-1 row-span-1"
              icon="lucide-map-pin"
            >
              Travel
            </SiteComponents.bento_card> --%>
          </div>

          <section :if={@posts != []}>
            <SiteComponents.home_section_title>
              Featured Articles
              <:addon><.link href="/articles" class="link">See all articles</.link></:addon>
            </SiteComponents.home_section_title>
            <SiteComponents.featured_posts posts={@posts} />
          </section>
        </div>
      </Layouts.page_content>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    posts = Blog.list_featured_posts() |> Enum.take(3)
    published_posts_count = Blog.list_published_posts() |> length()
    reading_count = Services.get_reading_stats()[:currently_reading] || 0

    if connected?(socket) do
      Process.send_after(self(), :refresh_music, @refresh_interval)
    end

    socket =
      socket
      |> assign(:post_count, published_posts_count)
      |> assign(:reading_count, reading_count)
      |> assign_async(:track, &get_currently_playing/0)

    {:ok, socket, temporary_assigns: [posts: posts]}
  end

  @impl true
  def handle_info(:refresh_music, socket) do
    Process.send_after(self(), :refresh_music, @refresh_interval)

    socket =
      socket
      |> assign_async(:track, &get_currently_playing/0)

    {:noreply, socket}
  end

  defp get_currently_playing do
    case Services.get_now_playing() do
      {:ok, %MusicTrack{} = track} -> {:ok, %{track: track}}
      error -> error
    end
  end
end
