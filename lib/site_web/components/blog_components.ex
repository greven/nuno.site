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
          <.link href={~p"/articles/#{@post.year}/#{@post}"} class="line-clamp-1">
            <span class="absolute inset-0"></span>
            {@post.title}
          </.link>
        </h2>
        <.post_category post={@post} class="hidden md:flex col-span-1 order-first" />
      </div>

      <.post_publication_date
        class="shrink-0 flex items-center font-headings text-content-40
          transition-colors group-hover:text-content-30"
        format="%b %d, %Y"
        post={@post}
      />
    </div>
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
        "font-medium text-3xl/10 sm:text-4xl/12 lg:text-5xl/14 text-center text-balance
          text-content-10",
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
        badge_class="group text-xs capitalize tracking-wider"
      >
        <.link navigate={~p"/category/#{@post.category}"}>
          <span class="text-content-30 tracking-wider group-hover:text-content-10 transition-colors">
            {@post.category}
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
        <.post_publication_date post={@post} show_icon={true} class="text-content-20" />
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

  @doc false

  attr :post, Blog.Post, required: true
  attr :date_format, :string, default: "%B %-d, %Y"
  attr :rest, :global

  def post_updated_disclaimer(assigns) do
    assigns =
      assigns
      |> assign(:post_updated?, Blog.post_updated?(assigns.post))

    ~H"""
    <div :if={@post_updated?} {@rest}>
      <div class="flex justify-center">
        <.badge badge_class="text-xs">
          Last updated on <span class="font-medium">{post_updated_date(@post, @date_format)}</span>
        </.badge>
      </div>
    </div>
    """
  end

  @doc false

  attr :next_post, Blog.Post, default: nil
  attr :prev_post, Blog.Post, default: nil
  attr :rest, :global

  def post_footer(assigns) do
    ~H"""
    <div {@rest}>
      <.post_pagination
        :if={@next_post || @prev_post}
        next_post={@next_post}
        prev_post={@prev_post}
        class="mt-8"
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
      |> assign(next_link: post_url(assigns.next_post))
      |> assign(prev_link: post_url(assigns.prev_post))

    ~H"""
    <div {@rest}>
      <div class="flex flex-col gap-2 md:grid md:grid-cols-2 md:space-between md:gap-4">
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
      <div class="group border border-surface-30 rounded-box p-4 transition hover:border-primary">
        <div class={["w-full", @dir == :next && "text-right"]}>
          <div class={["flex items-center gap-1", @dir == :next && "justify-end"]}>
            <.icon
              name={if @dir == :prev, do: "lucide-arrow-left", else: "lucide-arrow-right"}
              class="size-4 shrink-0 text-content-40/80 group-hover:-translate-x-0.5 transition-transform"
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
    <div class="relative border border-surface-30 rounded-box p-4 flex items-center
        justify-center text-content-30 opacity-40 select-none">
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
      class={["hidden sm:block fixed right-6 top-[364px] z-10", @class]}
      phx-hook="TableOfContents"
      {@rest}
    >
      <div class="relative isolate">
        <%!-- Navigator --%>
        <div id="toc-navigator" class="absolute top-0 right-0 p-4 translate-x-4" style="opacity: 1">
          <div class="w-fit px-2.5 py-2.5 bg-surface-10/90 border border-surface-40/80 rounded-full backdrop-blur-sm transition duration-500">
            <.toc_navigator headers={@headers} depth={@depth} />
          </div>
        </div>

        <%!-- Expanded --%>
        <div
          id="toc-list"
          class="invisible relative mb-20 p-5 min-w-[264px] max-w-[448px] bg-surface-10/95 border border-surface-30 rounded-box
            shadow-box backdrop-blur-sm z-10 transition-transform"
          style="translate: 500px"
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
          class="m-0 p-0 leading-5 text-content-10/20 transition ease-in-out duration-500 data-[active]:text-primary hover:text-content-40"
        >
          <a href={"##{header.id}"}>&ndash;</a>
          <span class="sr-only">{header.text}</span>
        </li>
      </ol>
    </div>
    """
  end

  @doc false

  attr :articles, :map,
    required: true,
    doc: "Map of articles to display, where each key is
      the group key and the values the list of articles"

  attr :icon, :string, default: "hero-calendar-days"
  attr :show_icon, :boolean, default: true
  attr :icon_class, :string, default: "flex items-center size-8 text-content-40"
  attr :header_container_class, :string, default: "flex items-center gap-4"
  attr :rest, :global

  slot :header do
    attr :class, :string
  end

  slot :items do
    attr :class, :string
  end

  def grouped_articles_list(assigns) do
    ~H"""
    <div {@rest}>
      <section :for={{key, articles} <- @articles}>
        <.header tag="h2" header_class="text-content-20 text-3xl">
          <div class={@header_container_class}>
            <.icon :if={@show_icon} name={@icon} class={@icon_class} />
            <%= for header <- @header do %>
              <div class={header[:class]}>
                {render_slot(header, key)}
              </div>
            <% end %>
          </div>
        </.header>

        <%= for items <- @items do %>
          <div class={items[:class]}>{render_slot(items, articles)}</div>
        <% end %>
      </section>
    </div>
    """
  end

  defp post_url(%Blog.Post{} = post),
    do: ~p"/articles/#{post.year}/#{post}"

  defp post_url(_), do: nil

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
