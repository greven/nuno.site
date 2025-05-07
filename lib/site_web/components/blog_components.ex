defmodule SiteWeb.BlogComponents do
  @moduledoc """
  Blog components and helpers.
  """

  use SiteWeb, :html

  alias Site.Blog
  alias Site.Support

  @doc false

  attr :post, Blog.Post, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def featured_post_item(assigns) do
    ~H"""
    <article class="group featured-article" {@rest}>
      <.header tag="h2" class="mt-2">
        <.link href={~p"/articles/#{@post.year}/#{@post}"} class="text-lg line-clamp-2">
          <span class="absolute inset-0 z-10"></span>
          <span class="group-hover:text-shadow-xs/15 text-shadow-primary">{@post.title}</span>
        </.link>
      </.header>

      <div class="h-5 flex items-center justify-between order-first">
        <.post_card_meta post={@post} format="%b %-d, %Y" class="text-content-40 text-sm" />
        <.post_category post={@post} />
      </div>

      <div class="-mt-1 text-sm text-content-40 text-pretty line-clamp-2 group-hover:text-content-30">
        {@post.excerpt}
      </div>
    </article>
    """
  end

  @doc false

  attr :post, Blog.Post, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def post_item(assigns) do
    ~H"""
    <div
      class={[
        "relative group flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between sm:gap-8",
        @class
      ]}
      {@rest}
    >
      <div class="flex md:grid md:grid-cols-[82px_auto_1fr] items-center gap-1">
        <h2 class="link-subtle text-base md:text-lg col-start-3 col-span-1 text-pretty line-clamp-2">
          <.link href={~p"/articles/#{@post.year}/#{@post}"}>
            <span class="absolute inset-0"></span>
            {@post.title}
          </.link>
        </h2>
        <.post_category post={@post} class="hidden md:flex col-span-1 order-first" />
      </div>

      <.post_publication_date
        class="shrink-0 flex items-center font-headings text-content-40/80 transition-colors group-hover:text-content-30"
        format="%b %d, %Y"
        post={@post}
      />
    </div>
    """
  end

  @doc false

  attr :post, Blog.Post, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def post_title(assigns) do
    ~H"""
    <h1
      class={["font-medium text-center text-balance text-3xl sm:text-4xl lg:text-5xl", @class]}
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
        color={Site.Blog.Post.type_color(@post.type)}
        badge_class="group text-xs capitalize tracking-wider"
      >
        <.link navigate={~p"/category/#{@post.type}"}>
          <span class="text-content-30 tracking-wider group-hover:text-content-10 transition-colors">
            {@post.type}
          </span>
        </.link>
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
      <.badge badge_class="group text-xs capitalize">
        <.link navigate={~p"/tag/#{@tag}"}>
          <span class="font-headings text-primary/90 group-hover:text-primary">#</span>
          <span class="text-content-30 tracking-wider group-hover:text-content-10 transition-colors">
            {@tag}
          </span>
        </.link>
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
      <div class="flex flex-wrap items-center justify-center gap-3 text-content-40">
        <.post_publication_date post={@post} show_icon={true} />
        <span class="font-sans text-xs text-primary">&bull;</span>
        <.post_read_time post={@post} label="read" show_icon={true} />

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

  @doc """
  Publication date / reading time display. It shows the date by default but toggled
  to show the reading time and animate the transition between the two.
  """

  attr :post, Blog.Post, required: true
  attr :show_icon, :boolean, default: true
  attr :format, :string, default: "%B %-d, %Y"
  attr :label, :string, default: nil
  attr :class, :string, default: nil

  def post_card_meta(assigns) do
    ~H"""
    <div class={["relative w-full h-full", @class]}>
      <.post_publication_date
        post={@post}
        show_icon={@show_icon}
        format={@format}
        class="absolute bottom-0 transitions duration-150 delay-150 group-hover:-translate-y-4 group-hover:opacity-0"
      />
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

  attr :value, :string, default: nil
  attr :icon, :string, default: nil
  attr :class, :string, default: nil
  attr :tag, :string, default: "div"
  attr :rest, :global

  slot :inner_block, required: true

  def post_meta_item(assigns) do
    ~H"""
    <.dynamic_tag tag_name={@tag} class={@class}>
      <div class="flex items-center gap-2 text-sm">
        <.icon :if={@icon} name={@icon} class="size-4.5 text-content-40" />
        <div class="flex items-center gap-1.5">
          <span :if={@value} class="font-mono text-content-20" {@rest}>{@value}</span>{render_slot(
            @inner_block
          )}
        </div>
      </div>
    </.dynamic_tag>
    """
  end

  @doc false

  attr :count, :integer, required: true
  attr :show_icon, :boolean, default: true
  attr :class, :string, default: nil

  def post_readers(assigns) do
    ~H"""
    <.post_meta_item
      icon={@show_icon && "lucide-users"}
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
  attr :class, :string, default: nil

  def post_views(assigns) do
    ~H"""
    <.post_meta_item
      icon={@show_icon && "lucide-printer"}
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
    <.post_meta_item icon={@show_icon && "lucide-clock"} value={"#{@duration}#{@unit}"} class={@class}>
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
    assigns = assign(assigns, :date, post_date(assigns.post.date, assigns.format))

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

  @doc false

  attr :headers, :list, required: true
  attr :class, :string, default: nil
  attr :depth, :integer, default: 1
  attr :rest, :global

  def table_of_contents(%{headers: headers} = assigns) do
    assigns =
      assigns
      |> assign(:has_links?, Enum.any?(headers, &(!!&1.id)))

    ~H"""
    <div
      :if={@headers != [] and @has_links?}
      id="toc"
      class={["hidden sm:block fixed right-6 top-[32%] z-10", @class]}
      phx-hook="TableOfContents"
      {@rest}
    >
      <div class="relative isolate">
        <%!-- Navigator --%>
        <div
          id="toc-navigator"
          class="absolute top-0 right-0 w-fit px-2.5 py-2.5 bg-surface-10/95
            border border-surface-40/80 rounded-full backdrop-blur-sm transition duration-500"
          style="opacity: 1"
        >
          <.toc_navigator headers={@headers} depth={@depth} />
        </div>

        <%!-- Expanded --%>
        <div
          id="toc-list"
          class="invisible relative p-5 min-w-[264px] bg-surface-10/95 border border-surface-30 rounded-box
            shadow-box backdrop-blur-sm z-10 transition-transform"
          style="transform: translateX(100vw)"
        >
          <div class="absolute -inset-4"></div>
          <div class="flex items-center justify-between gap-4">
            <div class="flex items-center gap-2.5">
              <.icon name="hero-list-bullet-mini" class="text-content-20/50 size-4.5" />
              <div class="font-headings text-content-30">Contents</div>
            </div>

            <div class="relative group flex items-center gap-1 text-sm text-content-40/75 isolate
              transition hover:text-content-10 hover:cursor-pointer">
              <a href="#" class="absolute inset-0 z-10"></a>
              <.icon
                name="hero-arrow-up"
                class="text-content-40/50 size-4 z-1 transition group-hover:text-secondary"
              /> Top
            </div>
          </div>

          <.toc_list headers={@headers} depth={@depth} class="mt-4" />
        </div>
      </div>
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
          class="group relative flex items-center text-sm text-content-40
            before:content-[''] before:absolute before:-left-[calc(--spacing(5)+1px)] before:w-px before:h-5
            before:border-l-2 before:border-l-transparent data-[active]:text-content-10 data-[active]:before:border-l-primary
            hover:text-content-20 transition-all"
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

  attr :headers, :list, required: true
  attr :depth, :integer, required: true
  attr :rest, :global

  defp toc_navigator(assigns) do
    ~H"""
    <div {@rest}>
      <ol class="space-y-1">
        <li
          :for={header <- @headers}
          :if={header.depth <= @depth}
          class="m-0 p-0 leading-5 text-content-10/20 data-[active]:text-primary hover:text-content-40"
        >
          <a href={"##{header.id}"} class="">
            &ndash;
          </a>
          <span class="sr-only">{header.text}</span>
        </li>
      </ol>
    </div>
    """
  end

  @doc """
  Show links to the previous (if available) and next articles.
  This is for navigation inside an article / post.
  """

  attr :rest, :global
  attr :next, Blog.Post, default: nil
  attr :prev, Blog.Post, default: nil

  def article_pagination(assigns) do
    assigns =
      assigns
      |> assign(next_link: post_url(assigns.next))
      |> assign(prev_link: post_url(assigns.prev))

    ~H"""
    <div {@rest}>
      <div class="flex">
        {@prev_link}
        {@next_link}
      </div>
    </div>
    """
  end

  defp post_url(%Blog.Post{} = post),
    do: ~p"/articles/#{post.year}/#{post}"

  defp post_url(_), do: nil
end
