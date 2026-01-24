defmodule SiteWeb.SiteComponents do
  @moduledoc """
  Site wide custom components.
  """

  use SiteWeb, :html

  @doc """
  Renders a duotone SVG icon using CSS masks given an icon name.
  All the available icons are Lucide (a small subset) icons located in the static
  images/icons directory. By default the icon class is `size-6 bg-primary`.
  """

  attr :name, :string, default: "box"
  attr :class, :string, default: "size-6 bg-primary"

  def duotone_icon(assigns) do
    ~H"""
    <span
      class={[
        "flex items-center justify-center mask-contain mask-center mask-no-repeat",
        @class
      ]}
      style={"mask-image:url('/images/icons/#{@name}-duotone.svg');"}
    >
    </span>
    """
  end

  @doc false

  attr :text, :string, default: "Back"
  attr :rest, :global, include: ~w(href navigate patch method disabled)

  def back_link(assigns) do
    ~H"""
    <.link {@rest}>
      <div class="group inline-flex items-center gap-2 text-sm font-medium text-content-40 underline-offset-3 hover:underline">
        <.icon
          name="hero-arrow-left-mini"
          class="size-4 -mr-0.5 shrink-0 text-content-40/80 transition-transform group-hover:-translate-x-0.5"
        />
        <span>{@text}</span>
      </div>
    </.link>
    """
  end

  @doc false

  attr :class, :string, default: nil
  attr :size, :integer, default: 40
  attr :rest, :global, include: ~w(href navigate patch method disabled)

  def avatar_picture(%{rest: rest} = assigns) do
    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link {@rest}>
        <div
          class="bg-white/80 p-px rounded-full shadow-sm shadow-neutral-800/10 dark:bg-neutral-800/90"
          style={"width:#{@size}px;height:#{@size}px;"}
        >
          <.avatar_image class={@class} />
        </div>
      </.link>
      """
    else
      ~H"""
      <div
        class="bg-white/80 p-px rounded-full shadow-sm shadow-neutral-800/10 dark:bg-neutral-800/90"
        style={"width:#{@size}px;height:#{@size}px;"}
      >
        <.avatar_image class={@class} {@rest} />
      </div>
      """
    end
  end

  attr :class, :string, default: nil
  attr :size, :integer, default: 40

  defp avatar_image(assigns) do
    ~H"""
    <.image
      use_picture
      src="/images/avatar.png"
      alt="avatar"
      height={@size}
      width={@size}
      class={[
        @class,
        "rounded-full object-cover",
        "hover:ring ring-primary ring-offset-2 ring-offset-surface transition-all"
      ]}
    />
    """
  end

  @doc false

  attr :size, :integer, default: 200
  attr :show_nav, :boolean, default: true
  attr :duration, :integer, default: 5000
  attr :class, :string, default: nil

  def profile_picture(assigns) do
    ~H"""
    <div class={@class}>
      <div
        id="profile-picture"
        class="profile-picture"
        phx-hook="ProfileSlideshow"
        data-duration={@duration}
      >
        <div class="slideshow-container" style={"width:#{@size}px;"}>
          <.slide
            src="/images/profile.png"
            size={@size}
            alt="Nuno's portrait"
            title="It's a me!"
            contrast
            active
          />
          <.slide
            src="/images/tram.png"
            size={@size}
            alt="A picture of a Lisbon's yellow tram"
            title="Lisbon"
          />
          <.slide
            src="/images/british.png"
            size={@size}
            alt="Picture of the London's British Museum"
            title="London!"
          />
          <.slide
            src="/images/leeds.png"
            size={@size}
            alt="Photo of Leeds, UK at night"
            title="Leeds <3"
          />
          <.slide
            src="/images/corn.png"
            size={@size}
            alt="Photo of Leeds' Corn Exchange"
            title="Leeds <3"
          />
          <.slide
            src="/images/beach.png"
            size={@size}
            alt="Picture of Nuno"
            title="It's a me again!"
            contrast
          />
          <.slide
            src="/images/lisbon.png"
            size={@size}
            alt="Photo of traditional Lisbon buildings"
            title="Lisbon"
          />

          <%!-- Navigation Buttons --%>
          <button :if={@show_nav} type="button" class="slideshow-nav-prev" aria-label="Previous image">
            <.icon name="hero-chevron-left-mini" class="size-6" />
          </button>

          <button :if={@show_nav} type="button" class="slideshow-nav-next" aria-label="Next image">
            <.icon name="hero-chevron-right-mini" class="size-6" />
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc false

  attr :src, :string, required: true
  attr :alt, :string, required: true
  attr :title, :string, required: true
  attr :size, :integer, default: 200
  attr :contrast, :boolean, default: false
  attr :active, :boolean, default: false

  def slide(assigns) do
    ~H"""
    <div class="slide" data-active={@active}>
      <div class="relative">
        <.image
          src={@src}
          alt={@alt}
          width={@size}
          height={@size}
          data-title={@title}
          use_picture
          use_blur
        />

        <div :if={@title} class="absolute bottom-4 w-full flex items-center justify-center">
          <span class={[
            "py-1 px-2 text-xs rounded-full backdrop-blur-sm",
            if(@contrast,
              do: "bg-white/15 text-white",
              else: "bg-black/30 text-white"
            )
          ]}>
            {@title}
          </span>
        </div>
      </div>
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
    <div class={["relative text-sm lg:text-base", @class]} {@rest}>
      <%= cond do %>
        <% @loading -> %>
          <div class="flex items-center gap-1.5">
            <span class="font-medium text-content-40/50 animate-pulse">Loading...</span>
          </div>
        <% @is_playing -> %>
          <div class="flex items-center gap-1.5">
            <.playing_icon is_playing={@is_playing} />
            <div class="font-medium text-emerald-600">Playing...</div>
          </div>
        <% @last_played -> %>
          <div class="flex items-center gap-1.5">
            <.icon
              name="hero-bolt-slash-solid"
              class="size-4 text-content-40 animate-pulse"
            />
            <span :if={@last_played} class="font-medium text-content-30">Offline</span>
            <.relative_time
              date={@last_played}
              class="hidden lg:block ml-0.5 text-sm font-headings text-content-40"
            />
          </div>
        <% true -> %>
          <div class="flex items-center gap-1.5">
            <.icon
              name="hero-bolt-slash-solid"
              class="size-4 text-content-40 animate-pulse"
            />
            <span class="font-medium text-content-30">Offline</span>
          </div>
      <% end %>
    </div>
    """
  end

  @doc false

  attr :is_playing, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global

  def playing_icon(assigns) do
    ~H"""
    <div class={["now-playing-icon", @class]} {@rest}>
      <span></span><span></span><span></span>
    </div>
    """
  end

  ## Kitchen Sink Components

  @doc """
  Render a color swatch for a given color.
  """

  attr :class, :string, default: nil
  attr :color, :string, required: true
  attr :label, :string, default: nil
  slot :inner_block

  def color_swatch(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-2">
      <div
        class="h-10 px-3 min-w-10 flex justify-center items-center rounded-lg border"
        style={"background: var(#{@color});border-color: color-mix(in oklch, var(#{@color}), #000 5%);"}
      >
        {render_slot(@inner_block)}
      </div>
      <div :if={@label} class="text-xs text-nowrap text-neutral-500">{@label}</div>
    </div>
    """
  end

  @doc """
  Protected email link component that obfuscates email addresses from spam bots.

  The email is split into user and domain parts and only revealed when the user
  clicks on the link. This provides protection against automated email scrapers.

  ## Examples

      <.email_link email="hello@example.com" class="link-ghost">
        Email
      </.email_link>

      <.email_link email="contact@example.com" icon="hero-envelope">
        Contact Us
      </.email_link>
  """
  attr :email, :string, required: true, doc: "the email address to protect"
  attr :class, :string, default: nil, doc: "additional CSS classes"
  attr :rest, :global, doc: "additional HTML attributes"
  slot :inner_block, required: true, doc: "the link text content"

  def email_link(assigns) do
    [user, domain] = String.split(assigns.email, "@", parts: 2)

    assigns =
      assigns
      |> assign(:user, user)
      |> assign(:domain, domain)

    ~H"""
    <a
      href="#"
      id={"email-link-#{SiteWeb.Helpers.use_id()}"}
      phx-hook="EmailLink"
      data-email-user={@user}
      data-email-domain={@domain}
      class={@class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </a>
    """
  end

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
      phx-hook="ArticleTableOfContents"
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
        border border-surface-30 shadow-sm rounded-full backdrop-blur-sm touch-manipulation"
      >
        <.icon name="hero-list-bullet-mini" class="text-content-40 size-6 pointer-events-none" />
      </div>

      <%!-- Desktop --%>
      <div
        id="toc-navigator-desktop"
        class={[
          "hidden sm:block w-fit px-2.5 py-2.5 bg-surface-10/80 border border-surface-40 shadow-xs rounded-full backdrop-blur-sm transition-colors duration-300",
          "hover:bg-surface-10 hover:border-primary hover:cursor-pointer"
        ]}
      >
        <ol class="space-y-1">
          <li
            :for={header <- @headers}
            :if={header.depth <= @depth}
            class="m-0 p-0 leading-5 text-content-10/20 transition ease-in-out duration-500
            data-active:text-primary"
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
        "fixed -bottom-2 left-1 right-1 w-full mb-1 p-5 z-10 rounded-t-lg",
        "sm:relative sm:mb-20 sm:w-auto sm:min-w-87 sm:rounded-lg",
        "bg-surface-10/95 border border-surface-30 shadow-xs backdrop-blur-sm",
        "transition-transform ease-in-out duration-500 touch-manipulation"
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
            before:h-5 before:border-l-2 before:border-l-transparent data-active:text-content-10
            data-active:before:border-l-primary hover:text-content-20 transition-all touch-manipulation"
        >
          <a href={"##{header.id}"} class="w-full line-clamp-1 touch-manipulation">
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
end
