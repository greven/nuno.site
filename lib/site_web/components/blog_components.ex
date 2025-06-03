defmodule SiteWeb.BlogComponents do
  @moduledoc """
  Blog components and helpers.
  """

  use SiteWeb, :html

  alias Site.Blog
  alias Site.Support

  alias SiteWeb.SiteComponents

  @doc false

  attr :post, Blog.Post, required: true
  attr :rest, :global

  def article(assigns) do
    ~H"""
    <.card tag="article" class="group isolate" {@rest}>
      <div class="blog-article">
        <.header tag="h2" class="mt-2">
          <.link href={~p"/articles/#{@post.year}/#{@post}"} class="text-lg line-clamp-2">
            <span class="absolute inset-0 z-10"></span>
            <span class="group-hover:text-shadow-xs/10 text-shadow-primary-dark">{@post.title}</span>
          </.link>
        </.header>

        <div class="h-5 flex items-center justify-between order-first">
          <.post_card_meta post={@post} format="%b %-d, %Y" class="text-content-40 text-sm" />
          <.post_category post={@post} />
        </div>

        <div class="-mt-2 text-sm text-content-40 line-clamp-2 group-hover:text-content-30">
          {@post.excerpt}
        </div>
      </div>
    </.card>
    """
  end

  @doc false

  attr :articles, :map,
    required: true,
    doc: "Map of articles to display, where each key is
      the group key and the values the list of articles"

  attr :icon, :string, default: "hero-calendar-days"
  attr :show_icon, :boolean, default: true

  attr :icon_class, :string, default: "hidden md:flex items-center size-8 text-content-40"

  attr :header_container_class, :string,
    default: "flex items-center justify-center md:justify-start gap-4"

  attr :sticky_header, :boolean, default: false
  attr :rest, :global

  slot :header do
    attr :class, :string
  end

  slot :items do
    attr :class, :string
  end

  def archive(assigns) do
    ~H"""
    <div {@rest}>
      <div class="[--archive-gap:48px] flex flex-col gap-(--archive-gap)">
        <section :for={{key, articles} <- @articles} class="group">
          <.header
            tag="h2"
            class={@sticky_header && "sticky top-(--header-height) bg-surface pt-4 z-1"}
            header_class="text-content-20 text-3xl font-medium md:font-normal"
          >
            <div class={@header_container_class}>
              <.icon :if={@show_icon} name={@icon} class={@icon_class} />
              <%= for header <- @header do %>
                <div class={header[:class]}>
                  {render_slot(header, key)}
                </div>
              <% end %>
            </div>
          </.header>

          <ol :for={items <- @items}>
            <li class={items[:class]}>{render_slot(items, articles)}</li>
          </ol>

          <.divider
            class="group-last:hidden mt-(--archive-gap) mx-8 md:mx-0"
            border_class="w-full border-t border-surface-40/90 border-dashed"
          />
        </section>
      </div>
    </div>
    """
  end

  @doc false

  attr :post, Blog.Post, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def archive_item(assigns) do
    ~H"""
    <article class={["relative flex flex-col px-6 md:p-0 text-center md:text-left", @class]} {@rest}>
      <h2 class="col-start-3 col-span-1">
        <.link
          href={~p"/articles/#{@post.year}/#{@post}"}
          class="link-subtle font-medium text-lg md:text-xl line-clamp-2 text-balance"
        >
          <span class="absolute inset-0"></span>
          {@post.title}
        </.link>
      </h2>

      <div class="mt-2 flex items-center justify-center md:justify-start gap-1 text-sm font-headings text-content-40">
        <.post_publication_date
          class="text-content-20 uppercase"
          show_icon={false}
          format="%b.%d"
          post={@post}
        />
        <span class="opacity-80">in</span><span class="text-content-20">{@post.category}</span>
      </div>

      <p class="my-4 font-light text-content-40 text-base/6 md:text-lg/7.5 text-balance line-clamp-3">
        {@post.excerpt}
      </p>
    </article>
    """
  end

  @doc false

  attr :post, Blog.Post, required: true
  attr :class, :string, default: nil
  attr :underline, :boolean, default: false
  attr :rest, :global

  def post_title(assigns) do
    ~H"""
    <h1
      class={[
        "font-medium text-3xl/10 sm:text-4xl/12 lg:text-5xl/14 text-content text-center text-balance",
        @underline &&
          "underline underline-offset-3 sm:underline-offset-4 lg:underline-offset-6
            decoration-[2px] md:decoration-[3px] decoration-primary",
        @class
      ]}
      {@rest}
    >
      {@post.title}
    </h1>
    """
  end

  @doc false

  attr :post, Blog.Post, required: true
  attr :class, :string, default: nil

  def post_category(assigns) do
    ~H"""
    <div class={["flex items-center", @class]}>
      <.badge
        variant="dot"
        color={Site.Blog.Post.category_color(@post.category)}
        badge_class="group bg-surface-10 text-xs capitalize tracking-wider"
        navigate={~p"/category/#{@post.category}"}
      >
        <span class="text-content-30 tracking-wider group-hover:text-content-10 transition-colors">
          {@post.category}
        </span>
      </.badge>
    </div>
    """
  end

  @doc false

  attr :post, Blog.Post, required: true
  attr :class, :string, default: nil

  def post_tags(assigns) do
    ~H"""
    <div class={@class}>
      <div class="flex items-center flex-wrap gap-1.5">
        <.post_tag :for={tag <- @post.tags} tag={tag} />
      </div>
    </div>
    """
  end

  @doc false

  attr :tag, :string, required: true
  attr :class, :string, default: nil

  def post_tag(assigns) do
    ~H"""
    <div class={@class}>
      <.badge badge_class="group bg-surface-10 text-xs capitalize" navigate={~p"/tag/#{@tag}"}>
        <span class="font-headings text-primary/90 group-hover:text-primary">#</span>
        <span class="text-content-30 tracking-wider group-hover:text-content transition-colors">
          {@tag}
        </span>
      </.badge>
    </div>
    """
  end

  @doc """
  Renders the post meta information, including the publication date and tags.
  """

  attr :post, Blog.Post, required: true
  attr :readers, :integer, default: nil
  attr :views, :integer, default: nil
  attr :class, :string, default: nil

  def post_meta(assigns) do
    ~H"""
    <div id="post-meta" class={@class} phx-hook="PostMeta">
      <div class="flex flex-wrap items-center justify-center gap-3 text-content-40 text-sm">
        <.post_publication_date post={@post} show_icon={true} class="text-content-20" />
        <span :if={@post.category == :blog} class="font-sans text-xs text-primary">&bull;</span>
        <.post_read_time :if={@post.category == :blog} post={@post} label="read" show_icon={true} />

        <%= if @views do %>
          <span class="hidden lg:inline font-sans text-xs text-primary">&bull;</span>
          <.post_views count={@views} class="hidden lg:inline-block" />
        <% end %>

        <%= if @readers do %>
          <span class="hidden md:inline font-sans text-xs text-primary">&bull;</span>
          <.post_readers count={@readers} class="hidden md:inline-block" />
        <% end %>
      </div>
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
          {@text} <span class="font-medium">{post_updated_date(@post, @date_format)}</span>
        </.badge>
      </div>
    </div>
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
      <div class="flex flex-wrap items-center justify-center gap-1.5">
        <.post_category post={@post} />
        <.post_tags post={@post} />
      </div>

      <.post_title class="mt-6" post={@post} />
      <.post_meta
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

  attr :post, Blog.Post, required: true
  attr :show_toc, :boolean, default: true

  def post_content(assigns) do
    ~H"""
    <article class="relative mt-10 md:mt-16 [--article-gap:16rem] lg:[--article-gap:16rem]">
      <.table_of_contents :if={@post.show_toc} headers={@post.headers} />
      <div class="prose">{raw(@post.body)}</div>
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
    <div class="mt-8 mb-4 flex flex-col gap-8">
      <.the_end />

      <div class={[
        "w-full flex justify-between flex-wrap gap-x-8 gap-y-4 px-4 py-3",
        "bg-surface-10/60 border border-surface-30 border-dashed rounded-box"
      ]}>
        <.post_authoring post={@post} class="shrink-0" />

        <div class="flex items-center gap-2.5">
          <.post_likes post={@post} count={@likes} />
          <.post_share post={@post} />
        </div>
      </div>

      <.post_pagination :if={@next_post || @prev_post} next_post={@next_post} prev_post={@prev_post} />
    </div>
    """
  end

  @doc false

  attr :post, Blog.Post, required: true
  attr :count, :integer, default: 0

  def post_likes(assigns) do
    assigns = assign(assigns, :likes, Support.abbreviate_number(assigns.count))

    ~H"""
    <.subtle_button
      id="post-like"
      size="xs"
      class="group relative overflow-visible!"
      phx-hook="PostLike"
      data-post-slug={"#{@post.year}-#{@post.slug}"}
    >
      <.icon
        data-unliked-icon
        name="hero-heart"
        class="size-5 text-content-30 group-hover:text-pink-400 transition-colors"
      />
      <.icon
        data-liked-icon
        name="hero-heart-solid"
        class="hidden size-5 text-pink-500 group-hover:text-pink-400 transition-colors"
      />
      <p data-likes-count class="ml-2 font-mono font-medium">{@likes}</p>
    </.subtle_button>
    """
  end

  @doc false

  attr :post, Blog.Post, required: true

  def post_share(%{post: post} = assigns) do
    assigns =
      assigns
      |> assign(:share_title, "#{post.title} - Nuno Moço")
      |> assign(:share_text, post.excerpt || "Check out this article by Nuno Moço.")
      |> assign(:share_url, post_url(post))

    ~H"""
    <div
      class="relative"
      id="share-post"
      phx-hook="SharePost"
      data-title={@share_title}
      data-text={@share_text}
      data-url={@share_url}
    >
      <.subtle_button size="xs" class="space-x-2">
        <.icon name="lucide-share" class="size-5" />
        <p class="font-medium">Share</p>
      </.subtle_button>

      <div id="share-container"></div>
    </div>
    """
  end

  @doc false

  attr :post, Blog.Post, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def post_authoring(assigns) do
    ~H"""
    <div class={["flex items-center gap-2.5", @class]} {@rest}>
      <SiteComponents.avatar_picture size={28} href={~p"/about"} />
      <div class="group flex items-center gap-1">
        <.link href={~p"/about"} class="font-headings text-sm md:text-base link-subtle">
          Nuno Moço
        </.link>

        <span class="hidden md:block font-sans text-xs text-content-40/60 mx-2">&bull;</span>

        <.post_publication_date
          post={@post}
          show_icon={false}
          format="%B %-d, %Y"
          class="hidden md:block text-content-40/95"
        />
      </div>
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
      |> assign(next_link: post_path(assigns.next_post))
      |> assign(prev_link: post_path(assigns.prev_post))

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
    <.link navigate={@link} {@rest}>
      <div class="group bg-surface-10 border border-surface-30 rounded-box p-4 transition hover:border-primary">
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
      </div>
    </.link>
    """
  end

  defp post_pager(assigns) do
    ~H"""
    <div class="min-h-[72px] relative border border-surface-30 rounded-box p-4 flex items-center
        justify-center text-content-30 opacity-40 select-none cursor-not-allowed">
      <div
        class="absolute inset-0 opacity-20 -z-10"
        style="background-image: repeating-linear-gradient(135deg, var(--color-content-40), var(--color-content-40) 1px, transparent 1px, transparent 6px);"
      >
      </div>
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
    """
  end

  @doc """
  Publication date / reading time display. It shows the date by default but toggled
  to show the reading time and animate the transition between the two.
  """

  attr :post, Blog.Post, required: true
  attr :show_icon, :boolean, default: true
  attr :format, :string, default: "%B %-d, %Y"
  attr :label, :string, default: nil
  attr :class, :string, default: nil

  def post_card_meta(%{post: post} = assigns) do
    assigns =
      assigns
      |> assign(:post_updated?, Blog.post_updated?(post))
      |> assign(:update_fresh?, post_is_fresh?(post))

    ~H"""
    <div class={["relative w-full h-full", @class]}>
      <div class="absolute flex items-center bottom-0 transitions duration-150 delay-150 group-hover:-translate-y-4 group-hover:opacity-0">
        <.post_publication_date post={@post} show_icon={@show_icon} format={@format} />

        <.badge :if={@post_updated? && @update_fresh?} badge_class="ml-2 text-xs" color="red">
          Updated
        </.badge>
      </div>

      <.post_read_time
        post={@post}
        label="read"
        show_icon={@show_icon}
        class="opacity-0 absolute inset-0 translate-y-4 transition delay-150 group-hover:opacity-100 group-hover:flex group-hover:translate-y-0"
      />
    </div>
    """
  end

  @doc false

  attr :tag, :string, default: "div"
  attr :value, :string, default: nil
  attr :icon, :string, default: nil
  attr :icon_class, :string, default: "size-5 text-content-40"
  attr :class, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def post_meta_item(assigns) do
    ~H"""
    <.dynamic_tag tag_name={@tag} class={@class}>
      <div class="flex items-center gap-2">
        <.icon :if={@icon} name={@icon} class={@icon_class} />
        <div class="flex items-center gap-1.5">
          <span :if={@value} class="font-mono text-content-20" {@rest}>{@value}</span>
          {render_slot(@inner_block)}
        </div>
      </div>
    </.dynamic_tag>
    """
  end

  @doc false

  attr :count, :integer, required: true
  attr :show_icon, :boolean, default: true
  attr :icon_class, :string, default: "size-5 text-content-40"
  attr :class, :string, default: nil

  def post_readers(assigns) do
    ~H"""
    <.post_meta_item
      icon={@show_icon && "lucide-users"}
      icon_class={@icon_class}
      value={@count}
      class={@class}
      data-readers-count
    >
      reading
    </.post_meta_item>
    """
  end

  @doc false

  attr :count, :integer, required: true
  attr :show_icon, :boolean, default: true
  attr :icon_class, :string, default: "size-5 text-content-40"
  attr :class, :string, default: nil

  def post_views(assigns) do
    assigns =
      assigns
      |> assign(count: Support.abbreviate_number(assigns.count))

    ~H"""
    <.post_meta_item
      icon={@show_icon && "lucide-printer"}
      icon_class={@icon_class}
      value={@count}
      class={@class}
      data-views-count
    >
      views
    </.post_meta_item>
    """
  end

  @doc """
  Renders the reading time of a post in minutes (or seconds if less than 1 minute).
  """

  attr :post, Blog.Post, required: true
  attr :label, :string, default: nil
  attr :show_icon, :boolean, default: true
  attr :icon_class, :string, default: "size-5 text-content-40"
  attr :class, :string, default: nil

  def post_read_time(%{post: %{reading_time: reading_time}} = assigns) do
    {duration, unit} =
      cond do
        reading_time < 1.0 -> {round(reading_time * 60), "s"}
        true -> {round(assigns.post.reading_time), "min"}
      end

    assigns =
      assigns
      |> assign(:duration, duration)
      |> assign(:unit, unit)

    ~H"""
    <.post_meta_item
      icon={@show_icon && "lucide-clock"}
      value={"#{@duration}#{@unit}"}
      icon_class={@icon_class}
      class={@class}
    >
      {@label}
    </.post_meta_item>
    """
  end

  @doc false

  attr :post, Blog.Post, required: true
  attr :show_icon, :boolean, default: true
  attr :format, :string, default: "%B %-d, %Y"
  attr :class, :string, default: nil

  def post_publication_date(assigns) do
    assigns =
      assigns
      |> assign(:date, post_date(assigns.post.date, assigns.format))

    ~H"""
    <.post_meta_item tag="time" icon={@show_icon && "lucide-calendar-fold"} class={@class}>
      {@date}
    </.post_meta_item>
    """
  end

  defp post_date(date, format) do
    case Support.time_ago(date) do
      %NaiveDateTime{} = datetime -> Calendar.strftime(datetime, format)
      relative_date -> relative_date
    end
  end

  defp post_updated_date(%Blog.Post{updated: %Date{} = date}, format) do
    Calendar.strftime(date, format)
  end

  defp post_updated_date(%Blog.Post{date: %Date{} = date}, format) do
    Calendar.strftime(date, format)
  end

  defp post_updated_date(_, _), do: nil

  @doc false

  attr :headers, :list, default: []
  attr :class, :string, default: nil
  attr :min_count, :integer, default: 1
  attr :depth, :integer, default: 1
  attr :rest, :global

  def table_of_contents(%{headers: headers} = assigns) do
    assigns =
      assigns
      |> assign(:has_links?, Enum.any?(headers, &(!!&1.id)))

    ~H"""
    <div
      :if={@headers != [] and @has_links? and length(@headers) > @min_count}
      id="toc"
      class={[
        "size-1 fixed bottom-0 right-1 z-10",
        "sm:top-[calc(var(--page-gap)+var(--article-gap))] sm:bottom-auto sm:left-auto sm:right-4",
        @class
      ]}
      phx-hook="TableOfContents"
      {@rest}
    >
      <div class="relative flex justify-end isolate">
        <.toc_navigator id="toc-navigator" headers={@headers} depth={@depth} />
        <.toc_content id="toc-container" headers={@headers} depth={@depth} />
      </div>
    </div>
    """
  end

  attr :headers, :list, required: true
  attr :depth, :integer, required: true
  attr :rest, :global

  defp toc_navigator(assigns) do
    ~H"""
    <div
      class={[
        "fixed bottom-2.5 right-2.5 p-2 transition ease-in-out duration-300",
        "sm:absolute sm:top-0 sm:right-0 sm:bottom-auto"
      ]}
      style="opacity: 1"
      {@rest}
    >
      <%!-- Mobile --%>
      <div
        id="toc-navigator-mobile"
        class="hidden sm:hidden items-center justify-center w-12 h-12 bg-surface-10/90
        border border-surface-30 shadow-sm rounded-full backdrop-blur-sm"
      >
        <.icon name="hero-list-bullet-mini" class="text-content-40 size-6" />
      </div>

      <%!-- Desktop --%>
      <div
        id="toc-navigator-desktop"
        class="hidden sm:block w-fit px-2.5 py-2.5 bg-surface-10/80
          border border-surface-30 shadow-xs rounded-full backdrop-blur-sm"
      >
        <ol class="space-y-1">
          <li
            :for={header <- @headers}
            :if={header.depth <= @depth}
            class="m-0 p-0 leading-5 text-content-10/20 transition ease-in-out duration-500
            data-[active]:text-primary hover:text-content-40"
          >
            <a href={"##{header.id}"} inert>&ndash;</a>
            <span class="sr-only">{header.text}</span>
          </li>
        </ol>
      </div>
    </div>
    """
  end

  attr :headers, :list, required: true
  attr :depth, :integer, required: true
  attr :rest, :global

  defp toc_content(assigns) do
    ~H"""
    <div
      id="toc-container"
      class={[
        "fixed -bottom-2 left-1 right-1 w-full mb-1 p-5 z-10 rounded-t-box",
        "sm:relative sm:mb-20 sm:w-auto sm:min-w-[348px] sm:rounded-box",
        "bg-surface-10/95 border border-surface-30 shadow-xs backdrop-blur-sm",
        "transition-transform ease-in-out duration-500"
      ]}
      style="opacity: 0; transform: translateY(400px);"
      inert
      {@rest}
    >
      <div class="absolute -inset-4"></div>

      <%!-- Container Header --%>
      <div class="flex items-center justify-between gap-4">
        <div class="flex items-center gap-2.5">
          <.icon name="hero-list-bullet-mini" class="text-content-20/50 size-4.5" />
          <div class="font-headings text-content-30">Contents</div>
        </div>

        <%!-- Go to Top --%>
        <div class="relative group sm:flex items-center gap-1 text-sm text-content-40/75 isolate
              transition hover:text-content-10 hover:cursor-pointer">
          <a href="#" class="absolute inset-0 z-10"></a>
          <.icon
            name="hero-arrow-up"
            class="text-content-40/50 size-4 z-1 transition group-hover:text-secondary"
          /> Top
        </div>
      </div>

      <.toc_list id="toc-headers" headers={@headers} depth={@depth} class="mt-4" />
    </div>
    """
  end

  attr :headers, :list, required: true
  attr :depth, :integer, required: true
  attr :rest, :global

  defp toc_list(assigns) do
    ~H"""
    <div {@rest}>
      <ol class="space-y-2.5">
        <li
          :for={header <- @headers}
          :if={header.depth <= @depth}
          phx-click={JS.dispatch("hide-toc")}
          class="group relative flex items-center text-sm text-content-40
            before:content-[''] before:absolute before:-left-[calc(--spacing(5)+1px)] before:w-px
            before:h-5 before:border-l-2 before:border-l-transparent data-[active]:text-content-10
            data-[active]:before:border-l-primary hover:text-content-20 transition-all"
        >
          <a href={"##{header.id}"} class="line-clamp-1">
            {header.text}
          </a>

          <.toc_list
            :if={header.subsections != []}
            class="mt-2 has-[ol]:pl-2.5"
            headers={header.subsections}
            depth={@depth}
          />
        </li>
      </ol>
    </div>
    """
  end

  @doc false

  def the_end(assigns) do
    ~H"""
    <div
      id="the-end"
      phx-hook="TheEnd"
      class="w-full flex items-center justify-center gap-1.5 font-sans text-xs"
    >
      <span class="the-end-dot transition-all duration-2000 ease-out text-content-40">
        &bull;
      </span>
      <span class="the-end-dot transition-all duration-2000 ease-out text-content-40">
        &bull;
      </span>
      <span class="the-end-dot transition-all duration-2000 ease-out text-content-40">
        &bull;
      </span>
    </div>
    """
  end

  defp post_path(%Blog.Post{} = post),
    do: ~p"/articles/#{post.year}/#{post}"

  defp post_path(_), do: nil

  defp post_url(%Blog.Post{} = post),
    do: url(~p"/articles/#{post.year}/#{post}")

  # Check if post has been recently posted or updated
  defp post_is_fresh?(%Blog.Post{} = post) do
    freshness_in_days =
      case post.category do
        :blog -> 30
        :note -> 7
        _ -> 0
      end

    posted_recently? = Date.diff(Date.utc_today(), post.date) < freshness_in_days
    updated_recently? = Blog.post_updated_within?(post, freshness_in_days)

    posted_recently? || updated_recently?
  end
end
