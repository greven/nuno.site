defmodule SiteWeb.HomeLive.Components do
  use SiteWeb, :html

  alias Phoenix.LiveView.AsyncResult

  alias SiteWeb.SiteComponents
  alias SiteWeb.BlogComponents

  @doc false

  attr :icon, :string, default: nil
  attr :variant, :atom, values: ~w(default static subtle)a, default: :default
  attr :size, :atom, values: ~w(small medium)a, default: :medium
  attr :content_class, :any, default: "h-full flex flex-col justify-between gap-2"
  attr :icon_class, :string, default: "size-8 text-primary"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href navigate patch method disabled)
  slot :inner_block, required: true

  def bento_card(assigns) do
    assigns =
      assigns
      |> assign_new(:bg, fn ->
        case assigns[:variant] do
          :default -> "bg-surface-10/80 hover:bg-surface-10"
          :static -> "bg-surface-10/80"
          :subtle -> "bg-surface-10/20 hover:bg-surface-10/30"
        end
      end)
      |> assign_new(:border, fn ->
        case assigns[:variant] do
          :default ->
            "border border-border hover:border-solid hover:border-primary transition-colors duration-150"

          :static ->
            "border border-border"

          :subtle ->
            "border border-dashed border-border/80 hover:border-border hover:border-solid transition-colors duration-150"
        end
      end)
      |> assign_new(:shadow, fn ->
        case assigns[:variant] do
          :default -> "hover:shadow-drop shadow-primary/15 dark:shadow-primary/20"
          :static -> nil
          :subtle -> "hover:shadow-xs"
        end
      end)

    ~H"""
    <.card
      border={@border}
      shadow={@shadow}
      class={@class}
      {@rest}
    >
      <.diagonal_pattern :if={@variant == :default} />

      <div class={[
        "h-full p-1",
        if(@size == :small, do: "flex items-center justify-center gap-3", else: @content_class)
      ]}>
        <.icon :if={@icon} name={@icon} class={@icon_class} />
        {render_slot(@inner_block)}
      </div>
    </.card>
    """
  end

  @doc false

  attr :loading, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global

  slot :label, required: true
  slot :value

  def card_content(assigns) do
    ~H"""
    <div class={["flex flex-col text-sm md:text-base", @class]} {@rest}>
      <%= if @loading do %>
        <div class="mt-1 flex flex-col gap-2">
          <.skeleton height="20px" width="120px" />
          <.skeleton height="18px" width="60%" />
        </div>
      <% else %>
        <div class="text-content-40">{render_slot(@label)}</div>
        <div class="font-medium">
          {render_slot(@value)}
        </div>
      <% end %>
    </div>
    """
  end

  @doc false

  attr :async_result, AsyncResult, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  slot :label, required: true
  slot :result, required: true

  def async_card_content(assigns) do
    ~H"""
    <div class={["flex flex-col text-sm md:text-base", @class]} {@rest}>
      <.async_result :let={result} assign={@async_result}>
        <:loading>
          <div class="mt-1 flex flex-col gap-2">
            <.skeleton height="20px" width="120px" />
            <.skeleton height="18px" width="60%" />
          </div>
        </:loading>

        <:failed :let={_failure}>
          <div class="text-content-40"></div>
          <div class="text-content-40/60">Not Available</div>
        </:failed>

        <div class="text-content-40">{render_slot(@label)}</div>
        <div class="font-medium">
          {render_slot(@result, result)}
        </div>
      </.async_result>
    </div>
    """
  end

  @doc false

  attr :class, :string, default: nil
  attr :icon, :string, default: nil
  attr :highlight, :string
  slot :inner_block, required: true
  slot :subtitle

  def home_section_title(assigns) do
    assigns =
      assign_new(assigns, :highlight_class, fn ->
        if assigns[:highlight], do: assigns[:highlight], else: "bg-content-30"
      end)

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

  attr :async, AsyncResult, required: true
  attr :posts, :list, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def social_feed_posts(assigns) do
    ~H"""
    <div class={@class} {@rest}>
      <.async_result assign={@async}>
        <:loading>
          <div class="flex items-center justify-center">
            <.card class="w-full h-[196px] md:w-[512px] lg:w-[564px] lg:h-[208px] animate-pulse">
              <div class="h-full flex items-start gap-3">
                <.skeleton height="38px" width="38px" class="rounded-full bg-surface-30" />

                <div class="w-full h-full flex flex-col justify-between">
                  <div class="flex flex-col gap-2.5">
                    <.skeleton height="16px" width="50%" />
                    <.skeleton height="14px" width="80%" class="mt-2 bg-surface-30 rounded-xs" />
                    <.skeleton height="14px" width="90%" />
                    <.skeleton height="14px" width="60%" />
                  </div>

                  <div class="flex gap-8 text-xs text-content-40/80">
                    <.skeleton height="12px" width="20%" />
                    <.skeleton height="12px" width="20%" />
                    <.skeleton height="12px" width="20%" />
                  </div>
                </div>
              </div>
            </.card>
          </div>
        </:loading>

        <:failed :let={_failure}>
          <div class="flex flex-col items-center justify-center h-48 md:h-52 lg:h-56 bg-surface-10 text-content-40/60">
            <.icon name="lucide-wifi-off" class="size-6 mb-2" /> Unable to load posts
          </div>
        </:failed>

        <%= if @posts != [] do %>
          <.card_stack
            id="social-feed-stack"
            class="w-full"
            items={@posts.inserts}
            container_class="w-full h-[196px] md:w-[512px] lg:w-[564px] lg:h-[208px]"
            phx-update={is_struct(@posts, Phoenix.LiveView.LiveStream) && "stream"}
            show_nav
            autoplay
          >
            <.card
              :for={{dom_id, post} <- @posts}
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
            </.card>
          </.card_stack>
        <% end %>
      </.async_result>
    </div>
    """
  end

  @doc false

  attr :posts, :list, default: []
  attr :class, :string, default: nil

  def featured_posts(assigns) do
    ~H"""
    <div class={@class}>
      <ol id="featured-posts" class="mx-auto flex flex-col justify-center gap-0.5">
        <%= for post <- @posts do %>
          <.card
            tag="li"
            class="relative"
            content_class="w-full h-full px-0 sm:px-2.5 lg:px-3 py-2.5 flex flex-col sm:flex-row sm:items-center justify-between gap-1.5 sm:gap-6"
            padding="p-0"
            border="border border-transparent border-dashed hover:border-solid hover:border-border"
            bg="bg-transparent hover:bg-surface-10"
          >
            <.diagonal_pattern use_transition={false} class="opacity-0 group-hover/card:opacity-60" />

            <%!-- Title --%>
            <div class="flex items-center gap-2 md:max-w-5/6">
              <.link
                class="link-subtle decoration-1 transition-none"
                navigate={~p"/articles/#{post.year}/#{post}"}
              >
                <span class="absolute inset-0 z-10"></span>
                <h3 class="font-medium text-content-20 group-hover/card:text-content-10 line-clamp-2 md:line-clamp-1">
                  {post.title}
                </h3>
              </.link>
            </div>

            <hr class="hidden flex-1 border-0.5 border-surface-40 border-dashed opacity-50 md:flex group-hover/card:opacity-0" />

            <%!-- Meta --%>
            <div class="flex items-center shrink-0 gap-2 text-sm md:justify-between">
              <BlogComponents.post_publication_date
                class="shrink-0 text-content-40  md:order-3"
                format="%b %d, %Y"
                show_icon={false}
                post={post}
              />

              <span class="opacity-10 md:flex md:order-2">|</span>

              <%!-- Tags --%>
              <div class="flex items-center flex-nowrap shrink-0 line-clamp-1 md:order-1">
                <span class="text-content-40/40 mr-1">#</span>
                <span class="text-content-40/50 group-hover:text-content-40">
                  {List.first(post.tags)}
                </span>
              </div>
            </div>
          </.card>
        <% end %>
      </ol>

      <div class="mt-4 md:mt-6 text-center">
        <.link
          navigate={~p"/articles"}
          class="group inline-block text-sm md:text-base font-medium link-subtle decoration-1"
        >
          View all articles
          <.icon
            name="lucide-arrow-right"
            class="size-4 ml-1 inline-block text-primary duration-200 group-hover:transform group-hover:translate-x-0.5 transition-transform"
          />
        </.link>
      </div>
    </div>
    """
  end

  @doc false

  def theme_switcher(assigns) do
    ~H"""
    <button
      id="theme-switcher"
      class="theme-switcher"
      type="button"
      aria-label="Toggle theme"
      phx-hook="ThemeSwitcher"
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        width="24"
        height="24"
        viewBox="0 0 24 24"
        stroke-width="1.5"
        stroke-linecap="round"
        stroke-linejoin="round"
      >
        <circle id="theme-switcher-sun" cx="12" cy="12" r="4" fill="currentColor" />
        <g id="theme-switcher-rays" stroke="currentColor">
          <path d="M12 2v2" /><path d="M12 20v2" /><path d="m4.93 4.93 1.41 1.41" /><path d="m17.66 17.66 1.41 1.41" />
          <path d="M2 12h2" /><path d="M20 12h2" /><path d="m6.34 17.66-1.41 1.41" /><path d="m19.07 4.93-1.41 1.41" />
        </g>

        <path
          id="theme-switcher-moon"
          fill="currentColor"
          d="M20.985 12.486a9 9 0 1 1-9.473-9.472c.405-.022.617.46.402.803a6 6 0 0 0 8.268 8.268c.344-.215.825-.004.803.401"
        />
      </svg>

      <div class="theme-switcher-led"></div>
    </button>
    """
  end

  @doc """
  A mini calendar a la iOS calendar icon.
  """

  attr :date, Date, default: Date.utc_today()

  def mini_calendar(assigns) do
    day_of_week = Date.day_of_week(assigns.date)
    day_of_week = Enum.at(Site.Support.days_of_week_names(:en), day_of_week - 1)

    assigns =
      assigns
      |> assign(:day, Date.utc_today().day)
      |> assign(:day_of_week, String.slice(day_of_week, 0..2))

    ~H"""
    <div class="flex flex-col items-center">
      <div class="font-mono text-primary">{@day_of_week}</div>
      <div class="font-medium text-content-10 text-4xl">
        {@day}
      </div>
    </div>
    """
  end
end
