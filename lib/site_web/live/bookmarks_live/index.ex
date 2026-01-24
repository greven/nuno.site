defmodule SiteWeb.BookmarksLive.Index do
  use SiteWeb, :live_view

  alias SiteWeb.BookmarksLive.Components

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      active_link={@active_link}
    >
      <Layouts.page_content class="flex flex-col gap-16">
        <.header>
          Bookmarks
          <:subtitle>
            Twenty years ago this was called a blogroll.
          </:subtitle>
        </.header>

        <p>
          Remember blogging? I do. Before social media and LLMs took over the internet, blogs were the primary way people shared
          their thoughts, ideas, and expertise online. Here are some of my favorite blogs and websites that I follow regularly to stay
          updated on various topics, including programming, design, technology, and more.
        </p>

        <div class="flex flex-col gap-12">
          <Components.bookmarks_section>
            <:title>Development</:title>

            <Components.bookmark_item
              title="Smashing Magazine"
              description="Web design, accessibility, UX and development."
              url="https://www.smashingmagazine.com/"
            />
            <Components.bookmark_item
              title="Piccalilli"
              description="Publication dedicated to front-end skills."
              url="https://piccalil.li/"
            />
            <Components.bookmark_item
              title="CSS {In Real Life}"
              description="Practical CSS advice and techniques."
              url="https://css-irl.info/"
            />
            <Components.bookmark_item
              title="Modern CSS"
              description="Stephanie Eckles blog on modern CSS techniques."
              url="https://moderncss.dev/"
            />
            <Components.bookmark_item
              title="Web.dev"
              description="Google's guidance to build modern web experiences."
              url="https://web.dev/"
            />
            <Components.bookmark_item
              title="CSS-Tricks"
              description="Tips, tricks, and techniques on CSS."
              url="https://css-tricks.com/"
            />
            <Components.bookmark_item
              title="A List Apart"
              description="Articles on web design, development, and meaning of web content."
              url="https://alistapart.com/"
            />
            <Components.bookmark_item
              title="Elixir Status"
              description="Elixir and Erlang ecosystem news from the community."
              url="https://elixirstatus.com/"
            />
          </Components.bookmarks_section>

          <Components.bookmarks_section>
            <:title>Design</:title>

            <Components.bookmark_item
              title="Hey Designer"
              description="Daily curated links focusing on UX design, modern CSS and design systems."
              url="https://heydesigner.com/"
            />
            <Components.bookmark_item
              title="Dribbble"
              description="Discover creative work and design inspiration."
              url="https://dribbble.com/"
            />
          </Components.bookmarks_section>
        </div>
      </Layouts.page_content>
    </Layouts.app>
    """
  end
end
