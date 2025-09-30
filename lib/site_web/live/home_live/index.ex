defmodule SiteWeb.HomeLive.Index do
  use SiteWeb, :live_view

  alias Site.Blog
  alias Site.Services
  alias Site.Services.MusicTrack

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
              A <.link navigate="/about" class="link">Software Engineer</.link> from Lisbon.
            </div>

            <p class="mt-8 max-w-3xl font-light text-base/7 md:text-xl/8 text-content-30 text-balance">
              This site is where I share my knowledge and ideas with others. Here you'll find a
              <.link navigate="/updates" class="link-subtle">collection</.link>
              of my <.link navigate="/articles?category=blog" class="link-subtle">articles</.link>, <.link
                navigate="/articles?category=note"
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
            <Components.bento_card
              navigate={~p"/articles"}
              class="col-span-1 row-span-1 aspect-square"
              icon="lucide-file-text"
            >
              <Components.card_content loading={is_nil(@post_count)}>
                <:label>Blog</:label>
                <:result>
                  {@post_count} {ngettext("Article", "Articles", @post_count)}
                </:result>
              </Components.card_content>
            </Components.bento_card>

            <Components.bento_card
              navigate={~p"/music"}
              class="col-span-1 row-span-1"
              icon="lucide-music"
            >
              <Components.now_playing track={@track} />
            </Components.bento_card>

            <Components.bento_card
              navigate={~p"/books"}
              class="col-span-1 row-span-1"
              icon="lucide-library"
            >
              <Components.async_card_content async_result={@reading_stats}>
                <:label>Reading</:label>
                <:result :let={result}>
                  {result[:currently_reading]} {ngettext("Book", "Books", result[:currently_reading])}
                </:result>
              </Components.async_card_content>
            </Components.bento_card>

            <Components.bento_card
              navigate={~p"/updates"}
              class="col-span-1 row-span-1"
              icon="lucide-history"
            >
              <Components.async_card_content async_result={@recent_updates}>
                <:label>Recent</:label>
                <:result :let={result}>
                  <%= if result && result > 0 do %>
                    {result} {ngettext("Update", "Updates", result)}
                  <% else %>
                    <div class="flex items-center gap-1 text-content-40">
                      {Enum.random([
                        "Nada",
                        "Zilch",
                        "Zero",
                        "None",
                        "Nichts",
                        "Rien",
                        "Void",
                        "Nil",
                        "Null"
                      ])}
                      <.icon name="lucide-frown" class="size-4" />
                    </div>
                  <% end %>
                </:result>
              </Components.async_card_content>
            </Components.bento_card>
          </div>

          <section :if={@posts != []}>
            <Components.home_section_title icon="lucide-newspaper" highlight="bg-primary">
              Featured Articles
            </Components.home_section_title>
            <Components.featured_posts posts={@posts} />
          </section>

          <section>
            <Components.home_section_title icon="lucide-origami" highlight="bg-secondary">
              Bluesky Updates
            </Components.home_section_title>
            <Components.social_feed_posts async={@skeets} posts={@streams.skeets} />
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
    end

    socket =
      socket
      |> assign(:post_count, published_posts_count)
      |> assign_async(:recent_updates, fn ->
        {:ok, %{recent_updates: Site.Updates.recent_updates_count()}}
      end)
      |> assign_async(:reading_stats, fn ->
        {:ok, %{reading_stats: get_reading_stats()}}
      end)
      |> assign_async(:track, &get_currently_playing/0)
      |> stream_configure(:skeets, dom_id: & &1.cid)
      |> stream_async(:skeets, fn -> {:ok, get_bluesky_posts(), limit: 5} end)

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

  defp get_bluesky_posts do
    case Services.get_latest_skeets("nuno.site") do
      {:ok, skeets} -> skeets |> Enum.take(5)
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
