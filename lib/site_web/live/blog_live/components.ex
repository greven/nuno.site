defmodule SiteWeb.BlogLive.Components do
  @moduledoc """
  Blog components and helpers.
  """

  use SiteWeb, :html

  alias Phoenix.LiveView.AsyncResult

  alias Site.Blog
  alias Site.Support
  alias Site.Services.Bluesky

  alias SiteWeb.SiteComponents
  alias SiteWeb.BlogComponents

  @doc false

  attr :post, Blog.Post, required: true
  attr :rest, :global

  def article(assigns) do
    ~H"""
    <article
      class={[
        "group relative isolate flex flex-col gap-4 rounded-xl border border-transparent border-dashed bg-transparent transition ease-in-out duration-150",
        "hover:bg-surface-20/60 hover:border-border/80 hover:backdrop-blur-xs",
        "md:flex-row md:gap-8 md:p-2"
      ]}
      {@rest}
    >
      <BlogComponents.article_thumbnail post={@post} />
      <div class="px-4 pb-3 md:px-0 md:py-2 flex flex-col">
        <BlogComponents.post_card_meta
          post={@post}
          format="%b %-d, %Y"
          class="font-light text-content-30 text-sm"
        />
        <.header tag="h2" class="mt-1" header_class="flex justify-between gap-8">
          <.link
            navigate={~p"/blog/#{@post.year}/#{@post}"}
            class="link-subtle text-lg xl:text-xl line-clamp-2"
          >
            <span class="absolute inset-0 z-10"></span>
            <span class="font-medium">{@post.title}</span>
          </.link>
        </.header>

        <p class="-mt-2 pr-2 text-sm/6 text-content-40 line-clamp-3 group-hover:text-content-30 md:mt-0">
          {@post.excerpt}
        </p>
      </div>
    </article>
    """
  end

  @doc false

  attr :post, Blog.Post, required: true
  attr :readers, :integer, default: nil
  attr :page_views, :integer, default: nil
  attr :class, :string, default: nil

  def post_header(assigns) do
    ~H"""
    <div class={@class}>
      <div class="text-center">
        <.link
          navigate={~p"/category/#{@post.category}"}
          class={[
            "font-medium tracking-widest text-xs uppercase",
            BlogComponents.category_color(@post.category)
          ]}
        >
          {@post.category}
        </.link>
      </div>

      <BlogComponents.post_title class="mt-4" post={@post} underline />
      <BlogComponents.post_meta
        post={@post}
        readers={@readers}
        views={@page_views}
        class="mt-4 md:mt-5 text-center"
      />

      <.post_updated_disclaimer post={@post} class="mt-8 text-center" />
    </div>
    """
  end

  @doc false

  attr :body, :string, required: true
  attr :headers, :string, required: true
  attr :show_toc, :boolean, default: true

  def post_content(assigns) do
    ~H"""
    <article class="relative mt-10 md:mt-16 [--article-gap:16rem] lg:[--article-gap:16rem]">
      <SiteComponents.table_of_contents :if={@show_toc} headers={@headers} />
      <div class="prose">{raw(@body)}</div>
    </article>
    """
  end

  @doc false

  attr :post, Blog.Post, required: true
  attr :next_post, Blog.Post, default: nil
  attr :prev_post, Blog.Post, default: nil
  attr :bsky_post, Bluesky.Post, default: nil
  attr :comments_async, AsyncResult, required: true
  attr :comments, :list, required: true
  attr :likes, :integer, default: 0

  def post_footer(assigns) do
    ~H"""
    <div class="mt-8 mb-4 flex flex-col gap-4">
      <.the_end />

      <BlogComponents.post_tags
        post={@post}
        class="mt-4 flex items-center justify-centers"
        badge_class="text-base"
      />

      <div class={[
        "w-full flex justify-between items-center gap-4 px-4 py-3",
        "bg-surface-10/60 border border-surface-30 border-dashed rounded-lg"
      ]}>
        <BlogComponents.post_author post={@post} />

        <div class="flex items-center gap-2.5">
          <.post_comments async={@comments_async} comments={@comments} bsky_post={@bsky_post} />
          <.post_likes post={@post} count={@likes} />
          <.post_share post={@post} />
        </div>
      </div>

      <.post_pagination
        :if={@next_post || @prev_post}
        next_post={@next_post}
        prev_post={@prev_post}
        class="mt-4"
      />
    </div>
    """
  end

  @doc false

  attr :async, AsyncResult, required: true
  attr :bsky_post, Bluesky.Post, default: nil
  attr :comments, :list, required: true
  attr :rest, :global

  def post_comments(assigns) do
    ~H"""
    <div {@rest}>
      <.async_result :let={_async} assign={@async}>
        <:loading>
          <.button variant="outline" size="sm" class="animate-pulse" disabled>
            <.icon name="lucide-message-square" class="text-content-30 opacity-40" />
            <p class="font-mono font-medium opacity-20">!</p>
          </.button>
        </:loading>

        <:failed :let={_failure}>
          <.button variant="outline" size="sm" title="Comments error!" disabled>
            <.icon name="lucide-message-square-off" class="opacity-80" />
          </.button>
        </:failed>

        <%= if @bsky_post do %>
          <.button
            variant="outline"
            size="sm"
            id="post-comments-button"
            phx-click={JS.dispatch("show-drawer", to: "#post-comments")}
          >
            <.icon name="lucide-message-square" class="text-content-30 opacity-40" />
            <p class={["font-mono font-medium", @bsky_post.reply_count == 0 && "opacity-50"]}>
              {@bsky_post.reply_count}
            </p>
          </.button>

          <.drawer id="post-comments" offset={8} position="right">
            <:header title="Comments" />

            <.box
              class="w-full mt-2 flex items-center gap-3 bg-surface-10"
              border="border border-border/50 bg-surface-20/40"
              with_pattern
            >
              <.icon name="lucide-messages-square" class="size-5 text-content-40" />
              <p class="text-content-10">
                Join the conversation
                <.external_link href={Bluesky.post_url(@bsky_post)} class="link decoration-sky-500">
                  on Bluesky
                </.external_link>
              </p>
            </.box>

            <%!-- Stats --%>
            <div class="mt-4 flex items-center gap-4">
              <div class="flex items-center">
                <div class="mr-1 text-content-20">{@bsky_post.reply_count}</div>
                <div class="text-content-40">
                  {ngettext("comment", "comments", @bsky_post.reply_count)}
                </div>
              </div>
              <span class="text-content-40/80">·</span>
              <div class="flex items-center">
                <div class="mr-1 text-content-20">{@bsky_post.like_count}</div>
                <div class="text-content-40">{ngettext("like", "likes", @bsky_post.like_count)}</div>
              </div>
              <span class="text-content-40/80">·</span>
              <div class="flex items-center">
                <div class="mr-1 text-content-20">{@bsky_post.repost_count}</div>
                <div class="text-content-40">
                  {ngettext("repost", "reposts", @bsky_post.repost_count)}
                </div>
              </div>
            </div>

            <%!-- Comments Thread --%>
            <div class="py-10 text-content-10">
              <%= if @bsky_post.reply_count == 0 do %>
                <.empty_comments_state />
              <% else %>
                <.comments_thread comments={@comments} />
              <% end %>
            </div>
          </.drawer>
        <% else %>
          <.button variant="outline" size="sm" title="Comments disabled" disabled>
            <.icon name="lucide-message-square-off" class="opacity-80" />
          </.button>
        <% end %>
      </.async_result>
    </div>
    """
  end

  attr :comments, :list, required: true

  defp comments_thread(assigns) do
    ~H"""
    <ul>
      <%= for {dom_id, parent_reply} <- @comments do %>
        <.comment
          post={parent_reply}
          has_replies={parent_reply.replies && parent_reply.replies != []}
        />
        <ul :if={parent_reply.replies && parent_reply.replies != []} data-replies>
          <%= for child_reply <- parent_reply.replies || [] do %>
            <.comment post={child_reply} depth={1} />
          <% end %>
        </ul>
      <% end %>
    </ul>
    """
  end

  attr :post, Bluesky.Post, required: true
  attr :has_replies, :boolean, default: false
  attr :depth, :integer, default: 0

  defp comment(assigns) do
    assigns =
      assigns
      |> assign(:display_name, comment_display_name(assigns.post))

    ~H"""
    <li class={[
      "group last:**:data-connector:hidden",
      @depth == 0 && "not-first:mt-8",
      @depth > 0 && "pl-4"
    ]}>
      <div class="relative pb-2">
        <span
          :if={@has_replies || @depth > 0}
          aria-hidden="true"
          data-connector
          class={[
            "absolute top-4 left-4 -ml-0.75 h-full w-0.5 bg-border/60",
            @depth > 0 && "left-10"
          ]}
        >
        </span>
        <span
          :if={@depth > 0}
          aria-hidden="true"
          class={[
            "not-group-first:hidden absolute top-4 left-0 -ml-0.75 h-4 w-8",
            "rounded-bl-xl border-l-2 border-b-2 border-border opacity-60"
          ]}
        >
        </span>

        <div class={["relative flex items-start space-x-3", @depth > 0 && "pl-6 pt-4"]}>
          <.image
            src={@post.avatar_url}
            width={28}
            height={28}
            alt="Bluesky Profile Picture"
            class="w-7 bg-surface-20 border border-border rounded-full shadow-sm shadow-neutral-800/10"
          />

          <%!-- Content --%>
          <div class="mt-1 min-w-0 flex-1">
            <%!-- Meta --%>
            <div class="h-full flex items-center gap-3.5 overflow-x-hidden">
              <div class="w-full shrink-0 text-sm line-clamp-1">
                <a
                  href={@post.url}
                  class="text-content-10 font-medium hover:underline"
                  target="_blank"
                >
                  {@display_name}
                </a>
                <span class="mx-1 text-content-40/50">·</span>
                <.relative_time date={@post.created_at} class="text-sm text-content-40" short />
              </div>
            </div>

            <%!-- Body --%>
            <div class="mt-2 flex flex-col justify-between">
              <div class="text-sm/6 text-content-30">
                {@post.text}
              </div>
            </div>
          </div>
        </div>
      </div>
    </li>
    """
  end

  defp comment_display_name(%Bluesky.Post{} = post) do
    cond do
      post.author_name != nil and post.author_name != "" ->
        post.author_name

      post.author_handle != nil and post.author_handle != "" ->
        post.author_handle

      true ->
        "Unknown User"
    end
  end

  defp empty_comments_state(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center text-center text-sm">
      <.icon name="lucide-message-square-off" class="size-8 text-content-30 opacity-60 mb-4" />
      <p class="text-content-30">No comments yet</p>
      <p class="text-content-40 mt-1">Be the first to comment on Bluesky!</p>
    </div>
    """
  end

  @doc false

  attr :post, Blog.Post, required: true
  attr :count, AsyncResult

  def post_likes(assigns) do
    ~H"""
    <.async_result :let={count} assign={@count}>
      <:loading>
        <.button variant="outline" size="sm" class="animate-pulse" inert>
          <.icon name="hero-heart" class="text-content-30 opacity-40" />
          <p class="font-mono font-medium opacity-40">-</p>
        </.button>
      </:loading>

      <:failed :let={_failure}>
        <.button variant="outline" size="sm" disabled>
          <.icon name="hero-heart" class="text-content-30 opacity-40" />
          <p class="font-mono font-medium opacity-40">-</p>
        </.button>
      </:failed>

      <%= if @count do %>
        <.button
          id="post-like"
          variant="outline"
          size="sm"
          class="group relative overflow-visible!"
          data-post-slug={"#{@post.year}-#{@post.slug}"}
          phx-hook="PostLike"
        >
          <.icon
            data-unliked-icon
            name="hero-heart"
            class="text-content-30 group-hover:text-pink-400 transition"
          />
          <.icon
            data-liked-icon
            name="hero-heart-solid"
            class="hidden text-pink-500 group-hover:text-pink-400 transition"
          />
          <p
            data-likes-count
            class="font-mono font-medium group-data-[liked=true]:text-pink-600 transition-colors"
          >
            {Support.abbreviate_number(count)}
          </p>
        </.button>
      <% end %>
    </.async_result>
    """
  end

  @doc false

  attr :post, Blog.Post, required: true

  def post_share(%{post: post} = assigns) do
    assigns =
      assigns
      |> assign(:share_title, "#{post.title} - Nuno Moço")
      |> assign(:share_text, post.excerpt || "Check out this article by Nuno Moço.")
      |> assign(:share_url, BlogComponents.post_url(post))

    ~H"""
    <div
      id="share-post"
      class="relative"
      phx-hook="SharePost"
      data-title={@share_title}
      data-text={@share_text}
      data-url={@share_url}
    >
      <.icon_button variant="outline" size="sm">
        <.icon name="lucide-share" class="size-4.5" />
        <p class="sr-only">Share</p>
      </.icon_button>

      <div id="share-container"></div>
    </div>
    """
  end

  @doc """
  Show links to the previous (if available) and next articles.
  This is for navigation inside an article / post.
  """

  attr :next_post, Blog.Post, default: nil
  attr :prev_post, Blog.Post, default: nil
  attr :rest, :global

  def post_pagination(assigns) do
    assigns =
      assigns
      |> assign(next_link: BlogComponents.post_path(assigns.next_post))
      |> assign(prev_link: BlogComponents.post_path(assigns.prev_post))

    ~H"""
    <div {@rest}>
      <div class="flex flex-col-reverse gap-2 md:grid md:grid-cols-2 md:space-between md:gap-4">
        <.post_pager dir={:prev} link={@prev_link} title={@prev_post && @prev_post.title} />
        <.post_pager dir={:next} link={@next_link} title={@next_post && @next_post.title} />
      </div>
    </div>
    """
  end

  attr :link, :string, required: true
  attr :title, :string, required: true
  attr :dir, :atom, values: ~w(prev next)a, required: true
  attr :rest, :global

  defp post_pager(%{link: link} = assigns) when not is_nil(link) do
    ~H"""
    <.card
      navigate={@link}
      border="border border-neutral-200 dark:border-neutral-800 hover:border-primary"
      shadow="shadow-xs"
      {@rest}
    >
      <.diagonal_pattern use_transition={false} />

      <div class={["w-full flex flex-col gap-0.5", @dir == :next && "text-right"]}>
        <div class={["flex items-center gap-1", @dir == :next && "justify-end"]}>
          <.icon
            name={if @dir == :prev, do: "lucide-arrow-left", else: "lucide-arrow-right"}
            class={[
              "size-4 shrink-0 text-content-40/80 transition-transform",
              @dir == :prev && "group-hover:-translate-x-0.5",
              @dir == :next && "group-hover:translate-x-0.5"
            ]}
          />
          <div :if={@dir == :prev} class="text-content-40 text-xs tracking-wider font-sans">
            Previous
          </div>
          <div
            :if={@dir == :next}
            class={[
              "text-content-40 text-xs tracking-wider font-sans",
              @dir == :next && "order-first"
            ]}
          >
            Next
          </div>
        </div>

        <div class="font-headings font-medium text-sm md:text-base line-clamp-1">{@title}</div>
      </div>
    </.card>
    """
  end

  defp post_pager(assigns) do
    ~H"""
    <.card
      class="select-none cursor-not-allowed"
      content_class="relative isolate h-full min-h-[72px] flex flex-col items-center justify-center"
      border="border border-neutral-200 dark:border-neutral-900"
      shadow="shadow-none"
      bg="bg-surface-10/50"
    >
      <.diagonal_pattern use_transition={false} />
      <div class="flex items-center justify-center text-content-40/50">
        <%= if @dir == :prev do %>
          <div class="font-headings font-medium text-sm md:text-base line-clamp-1">
            End of Time!
          </div>
        <% else %>
          <div class="font-headings font-medium text-sm md:text-base line-clamp-1">
            Start of Time!
          </div>
        <% end %>
      </div>
    </.card>
    """
  end

  @doc """
  Post "The End" indicator component with three animated dots.
  """

  def the_end(assigns) do
    ~H"""
    <div
      id="the-end"
      phx-hook="TheEnd"
      class="w-full flex items-center justify-center gap-1.5 font-sans text-xs"
    >
      <span class="the-end-dot transition-all duration-400 ease-out text-content-40">
        &bull;
      </span>
      <span class="the-end-dot transition-all duration-400 ease-out text-content-40">
        &bull;
      </span>
      <span class="the-end-dot transition-all duration-400 ease-out text-content-40">
        &bull;
      </span>
    </div>
    """
  end

  @doc false

  attr :post, Blog.Post, required: true
  attr :date_format, :string, default: "%B %-d, %Y"
  attr :text, :string, default: "Updated on"
  attr :rest, :global

  def post_updated_disclaimer(assigns) do
    assigns =
      assigns
      |> assign(:post_updated?, Blog.post_updated?(assigns.post))

    ~H"""
    <div :if={@post_updated?} {@rest}>
      <div class="flex justify-center">
        <.badge badge_class="ml-2 text-sm shadow-xs" color="sky">
          {@text}
          <span class="font-medium">{BlogComponents.post_updated_date(@post, @date_format)}</span>
        </.badge>
      </div>
    </div>
    """
  end
end
