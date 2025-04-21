defmodule SiteWeb.BlogComponents do
  @moduledoc """
  Blog components and helpers.
  """

  use SiteWeb, :html

  alias Site.Support

  @doc false

  attr :post, :any, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def post_item(assigns) do
    ~H"""
    <div class={["relative group flex items-center justify-between", @class]} {@rest}>
      <div class="flex md:grid md:grid-cols-[84px_auto_1fr] items-center gap-1">
        <.post_category post={@post} class="hidden md:flex col-span-1" />
        <h2 class="link-subtle font-normal text-base md:text-lg col-start-3 col-span-1">
          <.link href={~p"/articles/#{@post.year}/#{@post}"}>
            <span class="absolute inset-0"></span>
            {@post.title}
          </.link>
        </h2>
      </div>

      <.publication_date
        class="flex items-center text-content-40/80 text-sm md:text-base transition-colors group-hover:text-content-30"
        post={@post}
        format="%b %-d, %Y"
        show_icon={false}
      />
    </div>
    """
  end

  @doc false

  attr :post, :any, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def featured_post_item(assigns) do
    ~H"""
    <article
      class="relative group bg-surface-20/20 p-4 border-1 border-surface-30 shadow-xs rounded-box hover:border-primary transition-colors"
      {@rest}
    >
      <div class="mb-1 flex items-center justify-between">
        <.publication_date class="flex items-center text-content-40" post={@post} />
        <.post_category post={@post} />
      </div>

      <.header tag="h2">
        <.link href={~p"/articles/#{@post.year}/#{@post}"} class="text-2xl font-normal">
          <span class="absolute inset-0"></span>
          {@post.title}
        </.link>
      </.header>

      <div class="-mt-2 mb-1.5 text-content-40">
        {@post.excerpt}
      </div>

      <div class="mt-3 flex items-center text-primary">
        Read article
        <.icon
          name="hero-chevron-right-mini"
          class="size-3.5 mt-1 ml-1 motion-safe:group-hover:translate-x-1 transition-transform"
        />
      </div>
    </article>
    """
  end

  @doc false

  attr :post, :any, required: true
  attr :class, :string, default: nil

  def post_category(assigns) do
    ~H"""
    <div class={["flex items-center", @class]}>
      <.badge
        variant="dot"
        color={Site.Blog.Post.type_color(@post.type)}
        text_class="text-xs capitalize tracking-wider"
      >
        {@post.type}
      </.badge>
    </div>
    """
  end

  @doc false

  attr :post, :any, required: true
  attr :class, :string, default: nil

  def post_tags(assigns) do
    ~H"""
    <div class={@class}>
      <div class="flex items-center gap-1.5">
        <%= for tag <- @post.tags do %>
          <.badge text_class="text-xs capitalize tracking-wider">
            <span class="font-headings text-content-40/80 -mr-1">#</span>{tag}
          </.badge>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Renders the reading time of a post in minutes (or seconds if less than 1 minute).
  """

  attr :post, :any, required: true
  attr :label, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global

  def reading_time(%{post: %{reading_time: reading_time}} = assigns) do
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
    <span class={@class} {@rest}>
      <span class="font-normal text-content-20">{@duration}</span><span class="font-light text-content-30"><%= @unit %></span>
      <span :if={@label} class="font-light text-content-40">{@label}</span>
    </span>
    """
  end

  @doc false

  attr :post, :any, required: true
  attr :show_icon, :boolean, default: true
  attr :format, :string, default: "%B %-d, %Y"
  attr :class, :string, default: nil

  def publication_date(assigns) do
    assigns = assign(assigns, :date, post_date(assigns.post.date, assigns.format))

    ~H"""
    <time class={@class}>
      <.icon :if={@show_icon} name="hero-calendar" class="size-5 mr-2 text-content-40/80" />
      {@date}
    </time>
    """
  end

  defp post_date(date, format) do
    case Support.time_ago(date) do
      %NaiveDateTime{} = datetime -> Calendar.strftime(datetime, format)
      relative_date -> relative_date
    end
  end

  # @doc false

  # attr :class, :string, default: nil
  # attr :post, :any, required: true

  # def post_header(assigns) do
  #   ~H"""
  #   <div class={@class}>
  #     <.header>
  #       {@post.title}

  #       <:subtitle class="flex gap-2">
  #         <.publication_date post={@post} />
  #         <span class="text-secondary-400" aria-hidden="true">•</span>
  #         <span>
  #           <.reading_time time={@post.reading_time} />
  #           {gettext("read")}
  #         </span>
  #       </:subtitle>
  #     </.header>
  #   </div>
  #   """
  # end

  # attr :class, :string, default: nil
  # attr :readers, :integer, required: true
  # attr :today_views, :integer, required: true
  # attr :page_views, :integer, required: true

  # def post_sidebar(assigns) do
  #   ~H"""
  #   <div class={@class}>
  #     <.back navigate={~p"/writing/"} />
  #     <%!-- Stats --%>
  #     <div class="hidden lg:mt-6 lg:flex flex-col gap-2 text-xs font-medium text-secondary-500 uppercase">
  #       <div class="flex items-center gap-1.5 mb-2">
  #         <h3 class="font-headings text-sm font-semibold text-secondary-800">Statistics</h3>
  #       </div>

  #       <div class="pl-1">
  #         <span class="mr-1 text-secondary-700">
  #           {if @today_views, do: App.Helpers.format_number(@today_views), else: "-"}
  #         </span>
  #         {gettext("views today")}
  #       </div>

  #       <div class="pl-1">
  #         <span class="mr-1 text-secondary-700">
  #           {if @page_views, do: App.Helpers.format_number(@page_views), else: "-"}
  #         </span>
  #         {gettext("page views")}
  #       </div>

  #       <div class="pl-1">
  #         <span class="mr-1 text-secondary-700">{@readers}</span>
  #         {ngettext(
  #           "reader",
  #           "readers",
  #           @readers
  #         )}
  #       </div>
  #     </div>
  #   </div>
  #   """
  # end
end
