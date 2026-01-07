defmodule SiteWeb.HomeLive.Index do
  use SiteWeb, :live_view

  alias Site.Blog
  alias Site.Activity
  alias Site.Services
  alias Site.Services.MusicTrack

  alias SiteWeb.HomeLive.Components

  @refresh_interval 60_000

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
          <div class="flex items-center justify-center md:justify-start">
            <.link
              navigate="/about"
              id="hello"
              phx-hook="Hello"
            >
              <div class="mb-2 md:mb-0">
                <div
                  id="hello-text"
                  class="relative inline-block px-1.5 py-0.5 text-base md:text-xl bg-content/4 rounded-xs opacity-0"
                >
                  <div
                    id="hello-content"
                    class="flex items-center motion-safe:animate-[glitch_4s_ease-in-out]"
                    title="Yes, this is a Mr Robot reference!"
                  >
                    <.icon name="lucide-chevron-right" class="size-5 text-content-40/60 mr-0.5" />
                    <span
                      class="text-neutral-600 hover:text-neutral-700 transition-colors dark:text-neutral-500 hover:dark:text-neutral-400"
                      data-text="h3ll0, fr13nd!"
                    >
                    </span>
                    <span class="font-mono text-primary motion-safe:animate-blink">_</span>
                  </div>
                </div>
              </div>
            </.link>
          </div>

          <div id="site-intro" class="text-center md:text-left">
            <h1 class="flex flex-col font-headings leading-tight">
              <div class="-ml-1 md:-ml-2 text-6xl md:text-8xl tracking-tight">
                I'm
                <strong class="contrast-125 font-semibold">Nuno</strong><span class="text-primary">.</span>
              </div>
            </h1>

            <div class="text-md md:text-xl text-content-40">
              A <.link navigate="/about" class="link-subtle">Software Engineer</.link> from Lisbon.
            </div>

            <p class="mt-8 max-w-3xl font-light text-base/7 md:text-xl/8 text-content-30 text-balance">
              This site is where I share my knowledge and ideas with others. Here you'll find a
              <.link navigate="/changelog" class="link-subtle">collection</.link>
              of my <.link navigate="/blog?category=blog" class="link-subtle">articles</.link>, <.link
                navigate="/blog?category=note"
                class="link-subtle"
              >notes</.link>, and experiments.
            </p>
          </div>
        </section>

        <%!-- Content --%>
        <div class="flex flex-col gap-20 md:gap-28 last:mb-16">
          <%!-- Bento Grid --%>
          <div class="relative grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4 sm:p-2">
            <Components.bento_card
              navigate={~p"/blog"}
              class="col-span-1 row-span-1 aspect-square"
              icon="lucide-file-text"
            >
              <Components.card_content loading={is_nil(@post_count)}>
                <:label>The Blog</:label>
                <:value>
                  {@post_count} {ngettext("Article", "Articles", @post_count)}
                </:value>
              </Components.card_content>
            </Components.bento_card>

            <Components.bento_card
              navigate={~p"/music"}
              class="col-span-1 row-span-1 aspect-square"
              icon="lucide-music"
            >
              <Components.now_playing track={@track} />
            </Components.bento_card>

            <%!-- Multi-card --%>
            <div class="hidden col-span-1 row-span-1 aspect-square lg:grid grid-cols-2 grid-rows-2 gap-4">
              <%!-- <.tooltip label="Daily Pulse"> --%>
              <Components.bento_card
                navigate={~p"/pulse"}
                class="col-span-1 row-span-1 aspect-square"
                size={:small}
              >
                <Components.mini_calendar date={@today} />
              </Components.bento_card>
              <%!-- </.tooltip> --%>

              <%!-- <.tooltip label="Toggle Theme"> --%>
              <Components.bento_card
                class="hidden lg:block col-span-1 row-span-1 aspect-square"
                variant={:subtle}
                size={:small}
              >
                <Components.theme_switcher />
              </Components.bento_card>
              <%!-- </.tooltip> --%>

              <Components.bento_card
                navigate={~p"/changelog"}
                class="col-span-2 row-span-1"
                icon="lucide-history"
                size={:small}
              >
                <Components.card_content>
                  <:label>Changelog</:label>
                </Components.card_content>
              </Components.bento_card>
            </div>

            <div class="hidden lg:block col-span-1 row-span-1 aspect-square"></div>

            <Components.bento_card
              navigate={~p"/books"}
              class="col-span-1 row-span-1 aspect-square"
              icon="lucide-library"
            >
              <Components.async_card_content async_result={@reading_stats}>
                <:label>Reading</:label>
                <:result :let={result}>
                  {result[:currently_reading]} {ngettext(
                    "Book",
                    "Books",
                    result[:currently_reading]
                  )}
                </:result>
              </Components.async_card_content>
            </Components.bento_card>

            <Components.bento_card
              navigate={~p"/photos"}
              class="col-span-1 row-span-1 aspect-square"
              icon="lucide-image"
            >
              <Components.card_content loading={is_nil(@post_count)}>
                <:label>Photography</:label>
                <:value>
                  {@photos_count} {ngettext("Photo", "Photos", @photos_count)}
                </:value>
              </Components.card_content>
            </Components.bento_card>

            <Components.bento_card
              navigate={~p"/uses"}
              class="col-span-1 row-span-1 aspect-square"
              icon="lucide-layers"
            >
              <Components.card_content loading={is_nil(@post_count)}>
                <:label>Stack</:label>
                <:value>
                  What I use
                </:value>
              </Components.card_content>
            </Components.bento_card>

            <Components.bento_card
              navigate={~p"/bookmarks"}
              class="col-span-1 row-span-1 aspect-square"
              icon="lucide-bookmark"
            >
              <Components.card_content loading={is_nil(@post_count)}>
                <:label>Bookmarks</:label>
                <:value>My Blogroll</:value>
              </Components.card_content>
            </Components.bento_card>
          </div>

          <%!-- Activity Graph --%>
          <section>
            <Components.home_section_title>Activity</Components.home_section_title>
            <Components.activity_graph activity={@activity} class="mt-2" />
          </section>

          <%!-- Featured Articles --%>
          <section :if={@posts != []}>
            <Components.home_section_title>Featured Articles</Components.home_section_title>
            <Components.featured_posts posts={@posts} />
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

    if connected?(socket) do
      Process.send_after(self(), :refresh_music, @refresh_interval)
      Process.send_after(self(), :refresh_date, :timer.hours(1))
    end

    socket =
      socket
      |> assign(:page_title, "Home")
      |> assign(:today, Date.utc_today())
      |> assign(:post_count, published_posts_count)
      |> assign(:photos_count, 0)
      |> assign(:posts, posts)
      |> assign_async(:track, &get_currently_playing/0)
      |> assign_async(:activity, fn -> {:ok, %{activity: Activity.list_yearly_activity()}} end)
      |> assign_async(:reading_stats, fn -> {:ok, %{reading_stats: get_reading_stats()}} end)

    {:ok, socket, temporary_assigns: [posts: []]}
  end

  @impl true
  def handle_info(:refresh_music, socket) do
    Process.send_after(self(), :refresh_music, @refresh_interval)

    socket =
      socket
      |> assign_async(:track, &get_currently_playing/0)

    {:noreply, socket}
  end

  def handle_info(:refresh_date, socket) do
    Process.send_after(self(), :refresh_date, :timer.hours(1))
    {:noreply, assign(socket, :today, Date.utc_today())}
  end

  defp get_currently_playing do
    case Services.get_now_playing() do
      {:ok, %MusicTrack{} = track} -> {:ok, %{track: track}}
      error -> error
    end
  end

  defp get_reading_stats do
    case Services.get_reading_stats() do
      {:ok, stats} -> stats
      error -> error
    end
  end
end
