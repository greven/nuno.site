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
    <article class="featured-article group" {@rest}>
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
        <.post_reading_time post={@post} label="read" show_icon={true} />

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
      <.post_reading_time
        post={@post}
        label="read"
        show_icon={@show_icon}
        class="opacity-0 absolute inset-0 translate-y-4 transition delay-150 group-hover:opacity-100 group-hover:flex group-hover:translate-y-0"
      />
    </div>
    """
  end

  @doc false

  attr :count, :integer, required: true
  attr :show_icon, :boolean, default: true
  attr :class, :string, default: nil

  def post_readers(assigns) do
    ~H"""
    <div class={@class}>
      <div class="flex items-center gap-2">
        <.icon :if={@show_icon} name="lucide-users" class="size-4.5 text-content-40" />
        <span class="font-mono text-content-20 text-sm" data-readers-count>{@count}</span>reading
      </div>
    </div>
    """
  end

  @doc false

  attr :count, :integer, required: true
  attr :show_icon, :boolean, default: true
  attr :class, :string, default: nil

  def post_views(assigns) do
    ~H"""
    <div class={@class}>
      <div class="flex items-center gap-2">
        <.icon :if={@show_icon} name="lucide-printer" class="size-4.5 text-content-40" />
        <span class="font-mono text-content-20 text-sm">{@count}</span> views
      </div>
    </div>
    """
  end

  @doc """
  Renders the reading time of a post in minutes (or seconds if less than 1 minute).
  """

  attr :post, Blog.Post, required: true
  attr :label, :string, default: nil
  attr :show_icon, :boolean, default: true
  attr :class, :string, default: nil
  attr :text_class, :string, default: "text-content-40"

  def post_reading_time(%{post: %{reading_time: reading_time}} = assigns) do
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
    <span class={@class}>
      <div class="flex items-center gap-2">
        <.icon :if={@show_icon} name="lucide-clock" class={"size-4.5 #{@text_class}"} />
        <div>
          <span class="font-mono text-content-20 text-sm">{@duration}{@unit}</span>
          <span :if={@label} class={@text_class}>{@label}</span>
        </div>
      </div>
    </span>
    """
  end

  @doc false

  attr :author, :string, default: "Nuno Moço"
  attr :prefix, :string, default: nil
  attr :class, :string, default: nil

  def post_author(assigns) do
    ~H"""
    <div class={@class}>
      <div class="flex items-center gap-2">
        {if @prefix, do: "#{@prefix} ", else: ""} {@author}
      </div>
    </div>
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
    <time class={@class}>
      <div class="flex items-center gap-2">
        <.icon :if={@show_icon} name="lucide-calendar-fold" class="size-4.5 text-content-40" />
        <span class="font-mono text-sm">{@date}</span>
      </div>
    </time>
    """
  end

  defp post_date(date, format) do
    case Support.time_ago(date) do
      %NaiveDateTime{} = datetime -> Calendar.strftime(datetime, format)
      relative_date -> relative_date
    end
  end
end
