defmodule SiteWeb.BlogComponents do
  @moduledoc """
  Generic blog components and helpers.
  """

  use SiteWeb, :html

  alias Site.Blog
  alias Site.Support

  alias SiteWeb.SiteComponents

  @doc """
  Renders an image for an article given an image name (including path) or image URL.
  If a URL is given, it will use it as is. If an image name/path is given it will resolve to a full URL using
  the site's image CDN base URL. If the site CDN is used, we will use the image optimization parameters.
  """

  attr :image, :string, required: true
  attr :alt, :string, required: true
  attr :caption, :string, default: nil
  attr :class, :string, default: nil

  def article_image(assigns) do
    assigns = assign(assigns, :url, cdn_image_url(assigns.image))

    ~H"""
    <figure>
      <.image
        src={@url}
        alt={@alt}
        width={832}
        height={468}
        class={@class}
        title={@caption}
        use_picture
        use_blur
      />
      <figcaption :if={@caption}>{@caption}</figcaption>
    </figure>
    """
  end

  @doc false

  attr :post, Blog.Post, required: true
  attr :size, :integer, default: 250
  attr :rest, :global

  def article_thumbnail(assigns) do
    assigns =
      assigns
      |> assign(
        :base_class,
        [
          "w-full max-h-[200px] aspect-video rounded-md border border-border/50 shadow-sm object-cover",
          "md:w-44 md:aspect-square md:shrink-0"
        ]
      )
      |> assign(:image, article_thumbnail_url(assigns.post, "400w"))
      |> assign(:image_sm, article_thumbnail_url(assigns.post, "200w"))

    ~H"""
    <.image
      src={@image}
      alt={@post.title}
      width={@size}
      height={@size}
      class={[@base_class, !@post.image && "bg-surface-10/60"]}
      use_picture={if @post.image, do: true, else: false}
      {@rest}
    >
      <:source srcset={@image} type="image/jpeg" media="(max-width: 768px)" />
      <:source srcset={@image_sm} type="image/jpeg" media="(min-width: 769px)" />
    </.image>
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
            class={@sticky_header && "sticky top-(--header-height) z-1"}
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
    <.card tag="article" class={["text-center md:text-left", @class]} {@rest}>
      <div class="flex flex-col gap-1">
        <div class="flex items-center justify-center md:justify-start gap-1 text-sm font-headings text-content-40">
          <.post_publication_date
            class="text-content-40"
            show_icon={false}
            format="%b %-d, %Y"
            post={@post}
          />
          <span class="opacity-70">in</span><span class="text-content-20 capitalize">{@post.category}</span>
        </div>

        <h2 class="col-start-3 col-span-1">
          <.link
            navigate={~p"/blog/#{@post.year}/#{@post}"}
            class="link-subtle w-fit font-medium text-lg line-clamp-2 text-pretty"
          >
            <span class="absolute inset-0"></span>
            {@post.title}
          </.link>
        </h2>
      </div>

      <p class="mt-2 font-light text-sm md:text-base text-content-40 text-balance line-clamp-3">
        {@post.excerpt}
      </p>
    </.card>
    """
  end

  @doc """
  Publication date / reading time display. It shows the date by default but toggled
  to show the reading time and animate the transition between the two.
  """

  attr :post, Blog.Post, required: true
  attr :format, :string, default: "%B %-d, %Y"
  attr :class, :string, default: nil

  def post_card_meta(assigns) do
    assigns = assigns |> assign(:show_reading_time?, assigns.post.category == :article)

    ~H"""
    <div class={@class}>
      <div class="flex items-center gap-2 text-content-40">
        <.post_publication_date post={@post} show_icon={false} format={@format} />
        <span :if={@show_reading_time?} class="font-sans text-sm text-primary">&bull;</span>
        <.post_reading_time :if={@show_reading_time?} post={@post} show_icon={false} />
      </div>
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
        "font-medium text-3xl/10 sm:text-4xl/12 lg:text-5xl/14 text-content text-center text-balance",
        @underline &&
          "underline underline-offset-3 sm:underline-offset-4 lg:underline-offset-6 decoration-1 decoration-surface-40/75",
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
  attr :badge_class, :string, default: nil

  def post_tags(assigns) do
    ~H"""
    <div class={@class}>
      <div class="flex items-center flex-wrap gap-2">
        <.post_tag :for={tag <- @post.tags} tag={tag} badge_class={@badge_class} />
      </div>
    </div>
    """
  end

  @doc false

  attr :tag, :string, required: true
  attr :class, :string, default: nil
  attr :badge_class, :string, default: "text-sm md:text-base"

  def post_tag(assigns) do
    ~H"""
    <div class={@class}>
      <.badge class="group bg-surface-10" badge_class={@badge_class} navigate={~p"/tag/#{@tag}"}>
        <span class="font-headings text-content-40/80 group-hover:text-primary transition-colors">
          #
        </span>
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
  attr :show_tags, :boolean, default: false
  attr :show_icon, :boolean, default: true

  def post_meta(assigns) do
    ~H"""
    <div id="post-meta" class={@class} phx-hook="PostMeta">
      <div class="flex flex-wrap items-center justify-center gap-3 text-sm text-content-20">
        <.post_publication_date post={@post} show_icon={@show_icon} />
        <span :if={@post.category == :article} class="font-sans text-xs text-primary">&bull;</span>
        <.post_reading_time
          :if={@post.category == :article}
          post={@post}
          label="read"
          show_icon={@show_icon}
        />

        <%= if @views do %>
          <span class="hidden lg:inline font-sans text-xs text-primary">&bull;</span>
          <.post_views count={@views} class="hidden lg:inline-block" />
        <% end %>

        <%= if @readers do %>
          <span class="hidden md:inline font-sans text-xs text-primary">&bull;</span>
          <.post_readers count={@readers} class="hidden md:inline-block" />
        <% end %>

        <%= if @show_tags do %>
          <span class="hidden md:inline font-sans text-xs text-primary">&bull;</span>
          <div class="flex items-center flex-wrap gap-2">
            <span :for={tag <- @post.tags}>
              <span class="text-content-40/60 mr-px">#</span>{tag}
            </span>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc false

  attr :tag, :string, default: "div"
  attr :value, :string, default: nil
  attr :unit, :string, default: nil
  attr :icon, :string, default: nil
  attr :value_class, :string, default: nil
  attr :unit_class, :string, default: "ml-px"
  attr :content_class, :string, default: "not-first:ml-1.5"
  attr :icon_class, :string, default: "size-5 text-content-40"
  attr :class, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def post_meta_item(assigns) do
    ~H"""
    <.dynamic_tag tag_name={@tag} class={@class}>
      <div class="flex items-center gap-2">
        <.icon :if={@icon} name={@icon} class={@icon_class} />
        <div class="flex items-center">
          <span :if={@value} class={@value_class} {@rest}>{@value}</span>
          <span :if={@unit} class={@unit_class}>{@unit}</span>
          <span class={@content_class}>{render_slot(@inner_block)}</span>
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
      |> assign(abbr_count: Support.abbreviate_number(assigns.count))

    ~H"""
    <.post_meta_item
      icon={@show_icon && "lucide-printer"}
      icon_class={@icon_class}
      value={@abbr_count}
      class={@class}
      data-views-count
    >
      {ngettext("view", "views", @count)}
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

  def post_reading_time(%{post: %{reading_time: reading_time}} = assigns) do
    {duration, unit} =
      if reading_time < 1.0 do
        {round(reading_time * 60), "s"}
      else
        {round(assigns.post.reading_time), "min"}
      end

    assigns =
      assigns
      |> assign(:duration, duration)
      |> assign(:unit, unit)

    ~H"""
    <.post_meta_item
      icon={@show_icon && "lucide-clock"}
      value={@duration}
      unit={@unit}
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
  attr :format, :string, default: "%b %o, %Y"
  attr :class, :string, default: nil

  def post_publication_date(assigns) do
    assigns =
      assigns
      |> assign(:date, Support.format_date(assigns.post.date, format: assigns.format))

    ~H"""
    <.post_meta_item tag="time" icon={@show_icon && "lucide-calendar-fold"} class={@class}>
      {@date}
    </.post_meta_item>
    """
  end

  @doc false

  attr :post, Blog.Post, required: true
  attr :class, :string, default: nil
  attr :show_date, :boolean, default: true
  attr :rest, :global

  def post_author(assigns) do
    ~H"""
    <div class={["flex items-center justify-start gap-2.5", @class]} {@rest}>
      <SiteComponents.avatar_picture size={28} navigate={~p"/about"} />
      <div class="group flex items-center justify-start gap-1">
        <.link navigate={~p"/about"} class="font-headings text-base link-subtle">
          Nuno Moço
        </.link>

        <span :if={@show_date} class="hidden md:block font-sans text-xs text-content-40/80 mx-2">
          &bull;
        </span>

        <.post_publication_date
          :if={@show_date}
          post={@post}
          show_icon={false}
          class="hidden md:block font-light text-content-40"
        />
      </div>
    </div>
    """
  end

  ## Helpers

  @doc """
  Post updated formatted date.
  """
  def post_updated_date(%Blog.Post{updated: %Date{} = date}, format) do
    Calendar.strftime(date, format)
  end

  def post_updated_date(%Blog.Post{date: %Date{} = date}, format) do
    Calendar.strftime(date, format)
  end

  def post_updated_date(_, _), do: nil

  @doc """
  Category color helper.
  """
  def category_color(:article), do: "text-primary"
  def category_color(:note), do: "text-amber-500"
  def category_color(_), do: "text-gray-600"

  @doc """
  Post path helper.
  """
  def post_path(%Blog.Post{} = post), do: ~p"/blog/#{post.year}/#{post}"
  def post_path(_), do: nil

  @doc """
  Post URL helper.
  """
  def post_url(%Blog.Post{} = post), do: url(~p"/blog/#{post.year}/#{post}")

  def article_thumbnail_url(%Blog.Post{image: nil} = post, _size), do: cdn_image_url(post)

  def article_thumbnail_url(%Blog.Post{image: image_path}, size) do
    image_path
    |> Helpers.cdn_image_url()
    |> String.replace(~r/\.(jpg|jpeg|png|gif)$/, "_thumbnail_#{size}.jpg")
  end

  def cdn_image_url(%Blog.Post{image: nil} = post) do
    case post.category do
      :article -> "/images/icons.svg"
      :note -> "/images/note.svg"
      _ -> "/images/icons.svg"
    end
  end

  def cdn_image_url(%Blog.Post{image: image_path}) do
    Helpers.cdn_image_url(image_path)
  end

  def cdn_image_url(image_path) when is_binary(image_path) do
    Helpers.cdn_image_url(image_path)
  end
end
