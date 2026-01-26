defmodule SiteWeb.BlogLive.Components do
  @moduledoc """
  Blog components and helpers.
  """

  use SiteWeb, :html

  alias Site.Blog

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
      <div class="py-1 flex flex-col">
        <BlogComponents.post_card_meta
          post={@post}
          format="%b %-d, %Y"
          class="font-light text-content-30 text-sm"
        />
        <.header tag="h2" class="mt-1" header_class="flex justify-between gap-8">
          <.link
            navigate={~p"/blog/#{@post.year}/#{@post}"}
            class="link-subtle text-lg line-clamp-2"
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
          <BlogComponents.post_likes post={@post} count={@likes} />
          <BlogComponents.post_share post={@post} />
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
