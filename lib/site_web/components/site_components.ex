defmodule SiteWeb.SiteComponents do
  @moduledoc """
  Site wide custom components.
  """

  use SiteWeb, :html

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
      src="/images/pages/avatar.png"
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
            src="/images/pages/profile.png"
            size={@size}
            alt="Nuno's portrait"
            title="It's a me!"
            contrast
            active
          />
          <.slide
            src="/images/pages/tram.png"
            size={@size}
            alt="A picture of a Lisbon's yellow tram"
            title="Lisbon"
          />
          <.slide
            src="/images/pages/british.png"
            size={@size}
            alt="Picture of the London's British Museum"
            title="London!"
          />
          <.slide
            src="/images/pages/leeds.png"
            size={@size}
            alt="Photo of Leeds, UK at night"
            title="Leeds <3"
          />
          <.slide
            src="/images/pages/corn.png"
            size={@size}
            alt="Photo of Leeds' Corn Exchange"
            title="Leeds <3"
          />
          <.slide
            src="/images/pages/beach.png"
            size={@size}
            alt="Picture of Nuno"
            title="It's a me again!"
            contrast
          />
          <.slide
            src="/images/pages/lisbon.png"
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
end
