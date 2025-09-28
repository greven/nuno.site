defmodule SiteWeb.HomeLive.Components do
  use SiteWeb, :html

  alias Phoenix.LiveView.AsyncResult

  alias SiteWeb.SiteComponents
  alias SiteWeb.BlogComponents

  @doc false

  attr :icon, :string, default: "lucide-box"
  attr :content_class, :any, default: "h-full flex flex-col justify-between gap-2"
  attr :icon_class, :string, default: "size-8 text-primary"
  attr :rest, :global, include: ~w(href navigate patch method disabled)
  slot :inner_block, required: true

  def bento_card(assigns) do
    ~H"""
    <.card
      border="border border-border hover:border-solid hover:border-primary transition-colors duration-150"
      shadow="hover:shadow-drop shadow-primary/15 dark:shadow-primary/20"
      {@rest}
    >
      <.diagonal_pattern />

      <div class={["h-full p-1", @content_class]}>
        <.icon name={@icon} class={@icon_class} />
        {render_slot(@inner_block)}
      </div>
    </.card>
    """
  end

  @doc false

  attr :class, :string, default: nil
  attr :icon, :string, default: nil
  attr :highlight, :boolean, default: false
  attr :highlight_class, :string, default: "bg-content-30"
  slot :inner_block, required: true
  slot :subtitle

  def home_section_title(assigns) do
    ~H"""
    <header class={[@class, "flex flex-col items-center pb-6"]}>
      <div class="w-full flex items-center justify-center gap-2.5">
        <.icon :if={@icon} name={@icon} class="size-6.5 text-content-40/80" />
        <div class="relative">
          <div
            :if={@highlight}
            class={[
              "absolute bottom-1 left-0 right-0 top-2/3 opacity-15 dark:opacity-25 -z-1",
              @highlight_class
            ]}
          >
          </div>
          <h2 class="font-medium text-3xl text-content-10">{render_slot(@inner_block)}</h2>
        </div>
      </div>
      <p :if={@subtitle != []} class="font-light text-content-40">{render_slot(@subtitle)}</p>
    </header>
    """
  end

  @doc false

  attr :track, AsyncResult, required: true
  attr :show_artwork, :boolean, default: true
  attr :class, :string, default: nil
  attr :rest, :global

  def now_playing(assigns) do
    ~H"""
    <div class={["flex items-center", @class]} {@rest}>
      <.async_result :let={track} assign={@track}>
        <:loading>
          <div class="flex flex-col justify-center gap-0.5">
            <.playing_indicator loading />
            <div class="mt-1 flex flex-col gap-2">
              <.skeleton height="20px" width="120px" />
              <.skeleton height="18px" width="60%" />
            </div>
          </div>
        </:loading>

        <:failed :let={_failure}>
          <div class="flex items-center gap-4 text-content-40/60">
            <div class="flex flex-col gap-1">
              Not Available
            </div>
          </div>
        </:failed>

        <%= if track.name do %>
          <div class="flex flex-col justify-center">
            <.playing_indicator
              is_playing={track.now_playing}
              last_played={track.played_at}
            />
            <div class="mt-0.5 leading-5">
              <div class="text-sm md:text-base font-medium line-clamp-1">
                {track.name}
              </div>
              <div class="text-sm md:text-base text-content-30 line-clamp-1">
                {track.artist}
              </div>
            </div>
          </div>
        <% else %>
          <%!-- Offline & Not Available --%>
        <% end %>
      </.async_result>
    </div>
    """
  end

  @doc false

  attr :loading, :boolean, default: false
  attr :is_playing, :boolean, default: false
  attr :last_played, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global

  def playing_indicator(assigns) do
    ~H"""
    <div class={["relative text-sm", @class]} {@rest}>
      <%= cond do %>
        <% @loading -> %>
          <div class="flex items-center gap-1.5">
            <span class="font-medium text-content-40/50 animate-pulse">Loading...</span>
          </div>
        <% @is_playing -> %>
          <div class="flex items-center gap-2">
            <SiteComponents.playing_icon
              is_playing={@is_playing}
              style="--playing-color: var(--color-primary)"
            />
            <div class="font-medium text-primary">Now Playing</div>
          </div>
        <% @last_played -> %>
          <div class="flex items-center gap-2">
            <.icon
              name="lucide-history"
              class="size-4 text-content-40/80"
            />
            <span :if={@last_played} class="font-medium text-content-40/80">Last Played</span>
          </div>
        <% true -> %>
          <div class="flex items-center gap-2">
            <.icon
              name="hero-bolt-slash-solid"
              class="size-4 text-content-40/80"
            />
            <span class="font-medium text-content-40">Offline</span>
          </div>
      <% end %>
    </div>
    """
  end

  @doc false

  attr :posts, :list, default: []
  attr :class, :string, default: nil

  def social_feed_posts(assigns) do
    ~H"""
    <div class={@class}>
      <.card_stack
        id="social-feed-stack"
        class="w-full"
        items={@posts}
        container_class="w-full h-[196px] md:w-[512px] lg:w-[564px] lg:h-[208px]"
        show_nav
        autoplay
      >
        <.card
          :for={post <- @posts}
          class="absolute inset-0"
          bg="bg-surface-10"
          border="border border-surface-30 border-solid hover:border-surface-40 transition-colors"
          shadow="shadow-sm"
        >
          <div class="h-full flex items-start gap-3">
            <.image
              src={post.avatar_url}
              width={38}
              height={38}
              alt="Bluesky Profile Picture"
              class="border border-border rounded-full shadow-sm shadow-neutral-800/10"
            />

            <div class="h-full flex flex-col gap-1.5">
              <%!-- Meta --%>
              <a href={post.url} class="text-sm">
                <span class="text-content-10 font-medium">{post.author_name}</span>
                <span class="hidden md:inline-block text-content-40">@{post.author_handle}</span>
                <span class="mx-0.5 text-content-40/50">·</span>
                <.relative_time date={post.created_at} class="text-content-40" />
              </a>

              <%!-- Body --%>
              <div class="h-full flex flex-col justify-between">
                <div class="text-sm/6 text-content-40 line-clamp-4 lg:line-clamp-5">
                  {post.text}
                </div>

                <%!-- Footer --%>
                <div class="mt-1 flex gap-8 text-xs text-content-40/80">
                  <span class="flex items-center gap-1.5">
                    <.icon name="lucide-message-square" class="size-4 text-content-40/70" />
                    <span class="">{post.reply_count}</span>
                  </span>

                  <span class="flex items-center gap-1.5">
                    <.icon name="lucide-repeat" class="size-4 text-content-40/70" />
                    <span class="">{post.repost_count}</span>
                  </span>

                  <span class="flex items-center gap-1.5">
                    <.icon name="lucide-heart" class="size-4 text-content-40/70" />
                    <span class="">{post.like_count}</span>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </.card>
      </.card_stack>
    </div>
    """
  end

  @doc false

  attr :posts, :list, default: []
  attr :class, :string, default: nil

  def featured_posts(assigns) do
    ~H"""
    <div class={@class}>
      <ol id="featured-posts" class="max-w-3xl mx-auto flex flex-col justify-center gap-3">
        <%= for post <- @posts do %>
          <.card
            tag="li"
            class={[
              "relative group [counter-increment:item-counter]",
              "before:opacity-0 before:content-['#'_counter(item-counter)] before:absolute before:left-4.5 before:top-2.5 before:font-headings before:font-semibold before:text-content-10 md:before:opacity-10 before:text-xl before:pointer-events-none",
              "hover:before:opacity-25"
            ]}
            content_class="w-full px-2.5 lg:px-3 py-2.5 flex items-center justify-between gap-6"
          >
            <div class="max-w-5/6 flex items-center gap-2">
              <.link
                class="md:pl-12 link-subtle decoration-1 transition-none"
                navigate={~p"/articles/#{post.year}/#{post}"}
              >
                <span class="absolute inset-0 z-10"></span>
                <h3 class="font-medium text-xs md:text-sm line-clamp-1">{post.title}</h3>
              </.link>
            </div>

            <div class="flex items-center shrink-0 gap-2">
              <div class="hidden md:flex items-center flex-nowrap shrink-0 text-sm line-clamp-1">
                <span class="text-content-40/40 mr-1">#</span>
                <span class="text-content-40/50 group-hover:text-content-40">
                  {List.first(post.tags)}
                </span>
              </div>

              <span class="hidden opacity-10 md:flex">|</span>

              <BlogComponents.post_publication_date
                post={post}
                format="%b %d, %Y"
                class="shrink-0 text-xs text-content-40"
                show_icon={false}
              />
            </div>
          </.card>
        <% end %>
      </ol>
    </div>
    """
  end
end
