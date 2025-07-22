defmodule SiteWeb.HomeLive.Index do
  use SiteWeb, :live_view

  alias Site.Blog
  alias SiteWeb.SiteComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.home flash={@flash} active_link={@active_link}>
      <Layouts.page_content class="flex flex-col gap-16">
        <section id="hero">
          <.link href="/about" id="hello" phx-hook="Hello" class="text-center md:text-left">
            <div class="mb-2 md:mb-0">
              <div
                id="hello-text"
                class="relative inline-block px-1.5 py-0.5 text-base md:text-2xl bg-content/4 rounded-xs opacity-0"
              >
                <div
                  id="hello-content"
                  class="motion-safe:animate-[glitch_4s_ease-in-out]"
                  title="Yes, this is a Mr Robot reference!"
                >
                  <span class="text-neutral-700 dark:text-neutral-200" data-text="h3ll0, fr13nd!">
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

        <div class="flex flex-col gap-28 last:mb-16">
          <SiteComponents.bento_grid id="links" class="scroll-my-24" data-grid>
            <SiteComponents.bento_box navigate={~p"/articles"} class="col-span-1 row-span-1">
              Articles
            </SiteComponents.bento_box>

            <SiteComponents.bento_box navigate={~p"/travel"} class="col-span-1 row-span-1">
              Music
            </SiteComponents.bento_box>

            <SiteComponents.bento_box navigate={~p"/travel"} class="col-span-1 row-span-1">
              Lights
            </SiteComponents.bento_box>

            <SiteComponents.bento_box
              navigate={~p"/travel"}
              class="col-span-1 md:col-span-2 md:row-span-2"
            >
              Travel
            </SiteComponents.bento_box>
          </SiteComponents.bento_grid>

          <section :if={@posts != []}>
            <SiteComponents.home_section_title>Featured Articles</SiteComponents.home_section_title>
            <SiteComponents.featured_posts posts={@posts} />
          </section>
        </div>
      </Layouts.page_content>
    </Layouts.home>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    posts = Blog.list_featured_posts() |> Enum.take(3)

    {
      :ok,
      socket,
      temporary_assigns: [posts: posts]
    }
  end
end
