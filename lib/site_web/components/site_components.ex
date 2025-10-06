defmodule SiteWeb.SiteComponents do
  @moduledoc """
  Site wide custom components.
  """

  use SiteWeb, :html

  alias Phoenix.LiveView.AsyncResult

  alias Site.Support

  @doc false

  attr :class, :string, default: nil
  attr :size, :integer, default: 40
  attr :rest, :global, include: ~w(href navigate patch method disabled)

  def avatar_picture(%{rest: rest} = assigns) do
    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link {@rest}>
        <div
          class="bg-white/80 p-[1px] rounded-full shadow-sm shadow-neutral-800/10 dark:bg-neutral-800/90"
          style={"width:#{@size}px;height:#{@size}px;"}
        >
          <.avatar_image class={@class} />
        </div>
      </.link>
      """
    else
      ~H"""
      <div
        class="bg-white/80 p-[1px] rounded-full shadow-sm shadow-neutral-800/10 dark:bg-neutral-800/90"
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
        "hover:ring-2 ring-primary ring-offset-2 ring-offset-surface transition-all"
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
    <div
      id="profile-picture"
      class={["profile-picture", @class]}
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

  attr :rest, :global

  def contact_links(assigns) do
    ~H"""
    <div {@rest}>
      <ul class="flex flex-wrap justify-center items-center gap-2.5">
        <.contact_link href="mailto:hello@nuno.site" icon="hero-envelope" class="hidden md:block">
          Email
        </.contact_link>

        <.contact_link href="https://github.com/greven" icon="si-github">
          Github
        </.contact_link>

        <.contact_link href="https://bsky.app/profile/nuno.site" icon="si-bluesky">
          Bluesky
        </.contact_link>
      </ul>

      <ul class="mt-2 flex flex-wrap justify-center items-center gap-1">
        <.secondary_contact_link href="mailto:hello@nuno.site" class="md:hidden">
          Email
        </.secondary_contact_link>
        <.secondary_contact_link href="https://mastodon.social/@nuno_fm">
          Mastodon
        </.secondary_contact_link>
        <.secondary_contact_link href="https://www.linkedin.com/in/nuno-fr3ire/">
          LinkedIn
        </.secondary_contact_link>
        <.secondary_contact_link>Twitter</.secondary_contact_link>
      </ul>
    </div>
    """
  end

  @doc false

  attr :href, :string, required: true
  attr :icon, :string, required: true
  attr :rest, :global

  slot :inner_block, required: true

  def contact_link(assigns) do
    ~H"""
    <li {@rest}>
      <.button href={@href} size="sm" class="group">
        <.icon name={@icon} class="size-5" />
        {render_slot(@inner_block)}
        <.icon
          name="lucide-arrow-up-right"
          class="size-5 text-content-40 group-hover:text-primary transition-colors"
        />
      </.button>
    </li>
    """
  end

  @doc false

  attr :href, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def secondary_contact_link(%{href: link} = assigns) do
    if link do
      ~H"""
      <li {@rest}>
        <.link href={@href} class="px-1.5 link-subtle">
          {render_slot(@inner_block)}
        </.link>
      </li>
      """
    else
      ~H"""
      <li {@rest}>
        <s class="px-1.5 text-content-40/70 decoration-content-40/70">
          {render_slot(@inner_block)}
        </s>
      </li>
      """
    end
  end

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
        class="h-10 px-3 min-w-10 flex justify-center items-center rounded-lg border-1"
        style={"background: var(#{@color});border-color: color-mix(in oklch, var(#{@color}), #000 5%);"}
      >
        {render_slot(@inner_block)}
      </div>
      <div :if={@label} class="text-xs text-nowrap text-neutral-500">{@label}</div>
    </div>
    """
  end

  @doc false

  attr :items, :list, default: []
  attr :show_summary, :boolean, default: false
  attr :rest, :global

  def work_experience_list(assigns) do
    ~H"""
    <div {@rest}>
      <ul class="flex flex-col gap-8 divide-y divide-content-40/20 divide-dashed">
        <%= for item <- @items do %>
          <.experience_list_item
            role={item["role"]}
            company={item["company"]}
            location={item["location"]}
            start_date={item["start_date"]}
            end_date={item["end_date"]}
            show_summary={@show_summary}
            summary={item["summary"]}
            url={item["url"]}
          />
        <% end %>
      </ul>
    </div>
    """
  end

  @doc false

  attr :role, :string, required: true
  attr :company, :string, required: true
  attr :location, :string, default: nil
  attr :start_date, :string, default: nil
  attr :end_date, :string, default: nil
  attr :url, :string, default: nil
  attr :summary, :string, default: nil
  attr :show_summary, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global

  def experience_list_item(assigns) do
    ~H"""
    <li class="space-y-1 not-last:pb-8">
      <div class="flex items-center gap-1.5">
        <.icon name="hero-calendar-mini" class="size-4.5 text-content-40/90" />
        <span :if={@start_date} class="text-content-30/90 uppercase text-sm">
          <%= if @start_date && @end_date do %>
            {parse_date(@start_date)} - {parse_date(@end_date)}
          <% else %>
            {parse_date(@start_date)}
          <% end %>
        </span>
      </div>
      <div class="font-headings font-medium text-xl">
        {@role}<span class="ml-px text-primary text-xl">.</span>
      </div>
      <div class="text-content-20">
        <%= if @url do %>
          <.link href={@url} target="_blank" rel="noopener noreferrer" class="link-ghost">
            {@company}
          </.link>
        <% else %>
          {@company}
        <% end %>
        <span :if={@location} class="text-content-30">
          <span class="text-content-40/90">—</span> {@location}
        </span>
      </div>

      <div :if={@show_summary} class="mt-2 max-w-[72ch] font-light text-lg/7 text-content-40">
        {@summary}
      </div>
    </li>
    """
  end

  @doc false

  attr :items, :list, default: []
  attr :rest, :global

  def education_list(assigns) do
    ~H"""
    <div {@rest}>
      <ul class="flex flex-col gap-8 divide-y divide-content-40/20 divide-dashed">
        <%= for item <- @items do %>
          <.education_list_item
            area={item["area"]}
            institution={item["institution"]}
            location={item["location"]}
            study_type={item["study_type"]}
            start_date={item["start_date"]}
            end_date={item["end_date"]}
            courses={item["courses"]}
            url={item["url"]}
          />
        <% end %>
      </ul>
    </div>
    """
  end

  @doc false

  attr :area, :string, required: true
  attr :institution, :string, required: true
  attr :study_type, :string, default: nil
  attr :location, :string, default: nil
  attr :start_date, :string, default: nil
  attr :end_date, :string, default: nil
  attr :url, :string, default: nil
  attr :courses, :string, default: nil
  attr :show_start_date, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global

  def education_list_item(assigns) do
    ~H"""
    <li class="space-y-1 not-last:pb-8">
      <div class="flex items-center gap-1.5">
        <.icon name="hero-calendar-mini" class="size-4.5 text-content-40/90" />
        <span :if={@end_date} class="text-content-30/90 uppercase text-sm">
          <%= if @start_date && @end_date && @show_start_date do %>
            {parse_date(@start_date)} - {parse_date(@end_date)}
          <% else %>
            {parse_date(@end_date)}
          <% end %>
        </span>
      </div>

      <div class="mt-2 font-headings text-xl">
        <span :if={@study_type}>
          <span>{@study_type}</span>
          <span class="font-light text-content-40">in</span>
        </span>
        <span class="font-medium">{@area}</span><span class="text-primary text-xl">.</span>
      </div>
      <div class="text-content-20">
        <%= if @url do %>
          <.link href={@url} target="_blank" rel="noopener noreferrer" class="link-ghost">
            {@institution}<span :if={@location}> — {@location}</span>
          </.link>
        <% else %>
          {@institution}
        <% end %>
      </div>

      <div :if={@courses} class="mt-2 max-w-[72ch] font-light text-lg/7 text-content-40">
        {@courses}
      </div>
    </li>
    """
  end

  @doc false

  attr :items, :list, default: []
  attr :rest, :global

  def project_list(assigns) do
    ~H"""
    <div {@rest}>
      <ul class="flex flex-col gap-8 divide-y divide-content-40/20 divide-dashed">
        <%= for item <- @items do %>
          <.project_list_item
            name={item["name"]}
            context={item["context"]}
            description={item["description"]}
            start_date={item["start_date"]}
            end_date={item["end_date"]}
            location={item["location"]}
            url={item["url"]}
          />
        <% end %>
      </ul>
    </div>
    """
  end

  @doc false

  attr :name, :string, required: true
  attr :context, :string, required: true
  attr :description, :string, required: true
  attr :start_date, :string, default: nil
  attr :end_date, :string, default: nil
  attr :location, :string, default: nil
  attr :url, :string, default: nil

  def project_list_item(assigns) do
    ~H"""
    <li class="space-y-1 not-last:pb-8">
      <div class="font-headings font-medium text-xl">
        <span>{@name}</span><span class="text-primary text-xl"></span><span class="text-primary text-xl">.</span>
      </div>
      <div class="text-content-20">
        {@context}
        <span :if={@location} class="text-content-30">
          <span class="text-content-40/90">—</span> {@location}
        </span>
      </div>

      <div class="mt-2 flex items-center gap-1.5">
        <.icon name="hero-calendar-mini" class="size-4.5 text-content-40/90" />
        <span :if={@start_date} class="text-content-30/90 uppercase text-sm">
          <%= if @start_date && @end_date do %>
            {parse_date(@start_date)} - {parse_date(@end_date)}
          <% else %>
            {parse_date(@start_date)}
          <% end %>
        </span>
      </div>

      <div :if={@description} class="mt-2 max-w-[72ch] font-light text-lg/7 text-content-40">
        {@description}
      </div>
    </li>
    """
  end

  @doc false

  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :icon, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def resume_section_header(assigns) do
    ~H"""
    <.header
      tag="h2"
      class={[
        "relative xl:block",
        "before:content-['0'_counter(item-counter)] before:hidden lg:before:block before:absolute before:-left-28 before:top-0 before:text-7xl before:font-semibold before:font-headings
            before:text-primary before:text-right before:opacity-10 dark:before:saturate-0",
        @class
      ]}
      style="counter-increment: item-counter;"
      {@rest}
    >
      <div class="flex items-center gap-2.5">
        <.icon name={@icon} class="size-7 text-content-40" />
        <span>{@title}<span class="text-primary">.</span></span>
      </div>
      <:subtitle :if={@subtitle}>{@subtitle}</:subtitle>
    </.header>
    """
  end

  @doc false

  attr :track, AsyncResult, required: true
  attr :show_artwork, :boolean, default: true
  attr :class, :string, default: nil
  attr :rest, :global

  def now_playing(assigns) do
    ~H"""
    <div class={["flex items-center gap-2", @class]} {@rest}>
      <.async_result :let={track} assign={@track}>
        <:loading>
          <div class="-mt-0.5 flex items-center gap-4">
            <.track_image :if={@show_artwork} loading={true} class="size-30 md:size-32 lg:size-36" />
            <div class="flex flex-col gap-1">
              <div class="flex flex-col gap-2">
                <.playing_indicator loading />
                <.skeleton height="20px" width="182px" />
                <.skeleton height="14px" width="80%" />
                <.skeleton height="14px" width="60%" />
              </div>
            </div>
          </div>
        </:loading>

        <:failed :let={_failure}>
          <div class="flex items-center gap-4">
            <.track_image :if={@show_artwork} offline={true} class="size-30 md:size-32 lg:size-36" />
            <div class="flex flex-col gap-1">
              Failed to load track
            </div>
          </div>
        </:failed>

        <%= if track.name do %>
          <div class="flex items-center gap-4">
            <.track_image :if={@show_artwork} src={track.image} class="size-30 md:size-32 lg:size-36" />
            <div class="flex flex-col justify-center gap-1">
              <.playing_indicator is_playing={track.now_playing} last_played={track.played_at} />
              <div class="leading-5">
                <a
                  href={track.url}
                  target="_blank"
                  class="link-subtle font-medium text-base lg:text-xl hover:decoration-emerald-600"
                >
                  {track.name}
                </a>

                <div class="text-sm lg:text-base text-content-40 line-clamp-1">{track.album}</div>
                <div class="text-sm lg:text-base font-medium text-content-40 line-clamp-1">
                  {track.artist}
                </div>
              </div>
            </div>
          </div>
        <% else %>
          <%!-- Offline & Not Available --%>
          <div class="flex items-center gap-4">
            <.track_image offline={true} class="size-30 md:size-32 lg:size-36" />
            <div class="flex flex-col justify-center gap-1">
              <.playing_indicator is_playing={track.now_playing} last_played={track.played_at} />
              <div class="leading-5 line-clamp-1 text-content-40/50">
                n/a
                <div class="text-sm lg:text-base line-clamp-1">n/a</div>
                <div class="text-sm lg:text-base font-medium line-clamp-1">n/a</div>
              </div>
            </div>
          </div>
        <% end %>
      </.async_result>
    </div>
    """
  end

  @doc false

  attr :src, :string, default: nil
  attr :loading, :boolean, default: false
  attr :offline, :boolean, default: false

  attr :class, :string, default: nil

  attr :wrapper_class, :string,
    default: "w-full h-full relative aspect-square shrink-0 flex items-center justify-center"

  attr :image_width, :integer, default: 164
  attr :image_height, :integer, default: 164
  attr :image_class, :string, default: "object-cover brightness-110"

  attr :padding_class, :string, default: "p-0.5"
  attr :border_class, :string, default: "border-none"
  attr :shadow_class, :string, default: "shadow-md"
  attr :radius_class, :string, default: "rounded-md"
  attr :rest, :global

  def track_image(assigns) do
    ~H"""
    <div class={["shrink-0", @class]} {@rest}>
      <.box
        class={@wrapper_class}
        padding={@padding_class}
        border={@border_class}
        shadow={@shadow_class}
        bg="bg-surface-20/50"
      >
        <%= cond do %>
          <% @src -> %>
            <.image
              class={["shrink-0", @radius_class, @image_class]}
              alt="Album cover"
              src={@src}
              width={@image_width}
              height={@image_height}
            />
          <% @loading -> %>
            <.icon
              name="lucide-loader-circle"
              class="size-4/6 max-w-10 max-h-10 bg-surface-30 animate-spin"
            />
          <% @offline -> %>
            <.icon name="lucide-volume-off" class="size-4/6 max-w-10 max-h-10 bg-surface-30" />
          <% true -> %>
            <.icon name="lucide-volume-off" class="size-4/6 max-w-10 max-h-10 bg-surface-30" />
        <% end %>
      </.box>
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

  @doc false

  attr :async, AsyncResult, required: true
  attr :tracks, :list, required: true
  attr :rest, :global

  def recent_tracks(assigns) do
    ~H"""
    <div {@rest}>
      <.async_result assign={@async}>
        <:loading>
          <div class="min-h-80">
            <span class="font-medium text-content-40/50 animate-pulse">Loading...</span>
          </div>
        </:loading>

        <%= if @tracks != [] do %>
          <ul
            id="recent-tracks"
            class="w-full flex flex-col gap-2 text-content-10 text-sm md:text-base"
            phx-update={is_struct(@tracks, Phoenix.LiveView.LiveStream) && "stream"}
          >
            <li
              :for={{dom_id, track} <- @tracks}
              class="flex items-center gap-4 md:gap-6"
              id={dom_id}
            >
              <.track_image
                src={track.image}
                class="size-10"
                padding_class="p-0"
                radius_class="rounded-sm"
              />
              <div class="flex-1 flex flex-col md:gap-1 md:flex-row md:items-center">
                <%!-- Track name --%>
                <div class="flex items-center gap-2">
                  <div class="font-medium text-sm md:text-base md:font-normal text-content-20 whitespace-nowrap text-ellipsis line-clamp-1 shrink-0">
                    <a href={track.url} target="_blank" class="link-ghost">{track.name}</a>
                  </div>
                  <.playing_icon
                    :if={track.now_playing}
                    class="shrink-0 mr-1"
                    style="--playing-color: var(--color-surface-40)"
                  />
                </div>

                <hr class="hidden w-full border-0.5 border-surface-40 border-dashed opacity-70 md:flex" />

                <%!-- Track artist --%>
                <div class={[
                  "text-sm md:text-base font-light text-content-40 whitespace-nowrap text-ellipsis line-clamp-1 shrink-0",
                  "md:ml-2 md:text-right"
                ]}>
                  {track.artist}
                </div>
              </div>
            </li>
          </ul>
        <% else %>
          <div class="flex items-center">
            <.icon name="hero-bolt-slash-solid" class="mt-2 size-6 text-content-40/20" />
          </div>
        <% end %>
      </.async_result>
    </div>
    """
  end

  @doc false

  attr :id, :string, default: "spotify-playlists"
  attr :async, AsyncResult, required: true
  attr :playlists, :list, required: true
  attr :rest, :global

  def spotify_playlists(assigns) do
    ~H"""
    <div {@rest}>
      <.async_result assign={@async}>
        <:loading>
          <ul class="grid grid-cols-2 md:grid-cols-3 gap-2.5">
            <%= for _ <- 1..6 do %>
              <.card padding="p-1">
                <div class="flex items-center gap-2 overflow-hidden">
                  <.track_image
                    loading={true}
                    image_width={50}
                    image_height={50}
                    shadow_class="shadow-none"
                    padding_class="p-0"
                    class="size-12.5 flex items-center"
                  />

                  <div class="w-full flex flex-col gap-1.5">
                    <.skeleton height="16px" width="60%" />
                    <.skeleton height="14px" width="40%" />
                  </div>
                </div>
              </.card>
            <% end %>
          </ul>
        </:loading>

        <:failed :let={_failure}>
          <div class="flex items-center gap-2">
            <.icon name="hero-bolt-slash-solid" class="text-content-40/20" />
            <div class="text-content-40/50">Failed to load playlists</div>
          </div>
        </:failed>

        <ul class="grid grid-cols-2 md:grid-cols-3 gap-2.5">
          <.playlist_item :for={{dom_id, playlist} <- @playlists} playlist={playlist} />
        </ul>
      </.async_result>
    </div>
    """
  end

  @doc false

  attr :playlist, :map, required: true
  attr :rest, :global

  def playlist_item(assigns) do
    ~H"""
    <.card
      tag="li"
      class="group relative"
      padding="p-1"
    >
      <div class="flex gap-2 overflow-hidden">
        <.track_image
          src={@playlist.image}
          image_width={50}
          image_height={50}
          shadow_class="shadow-none"
          padding_class="p-0"
        />

        <a
          href={@playlist.url}
          target="_blank"
          class="p-1 flex flex-col justify-center"
          {@rest}
        >
          <div class="absolute inset-0"></div>
          <span class="font-headings font-medium text-xs sm:text-sm text-ellipsis line-clamp-1">
            {@playlist.name}
          </span>
          <p class="text-xs text-content-40">{@playlist.songs} songs</p>
        </a>
      </div>
      <.icon
        name="lucide-arrow-up-right"
        class="hidden md:block size-5 text-surface-40/80 absolute top-2 right-2 transition group-hover:text-emerald-600"
      />
    </.card>
    """
  end

  @doc false

  attr :id, :string, default: "top-artists-list"
  attr :async, AsyncResult, required: true
  attr :items, :list, required: true
  attr :rest, :global

  def top_artists_list(assigns) do
    ~H"""
    <div {@rest}>
      <.async_result assign={@async}>
        <:loading>
          <div class="min-h-80">
            <span class="font-medium text-content-40/50 animate-pulse">Loading...</span>
          </div>
        </:loading>

        <%= if @items != [] do %>
          <ol
            id={@id}
            class={[
              "list-[style:decimal-leading-zero] list-inside marker:text-content-40/80",
              "grid grid-cols-1 md:grid-cols-2 gap-y-1 md:gap-x-16"
            ]}
            phx-update={is_struct(@items, Phoenix.LiveView.LiveStream) && "stream"}
          >
            <li
              :for={{dom_id, item} <- @items}
              class={[
                "group max-h-[34px] text-base/7 font-light transition-colors border-b-1 border-border/40 overflow-hidden",
                "md:text-lg/8 hover:marker:text-primary"
              ]}
              id={dom_id}
            >
              <a href={item.url} target="_blank" class="link-ghost">{item.name}</a>
              <span
                :if={item.playcount}
                class="font-light text-content-40/50 group-hover:text-content-40 transition-colors"
              >
                ({Support.format_number(item.playcount, 0)})
              </span>
            </li>
          </ol>
        <% else %>
          <div class="flex items-center">
            <.icon name="hero-bolt-slash-solid" class="mt-2 size-6 text-content-40/20" />
          </div>
        <% end %>
      </.async_result>
    </div>
    """
  end

  @doc false

  attr :id, :string, default: "albums-grid"
  attr :async, AsyncResult, required: true
  attr :albums, :list, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def albums_grid(assigns) do
    ~H"""
    <div class={@class} {@rest}>
      <.async_result :let={_async} assign={@async}>
        <:loading>
          <div class="min-h-80">
            <span class="font-medium text-content-40/50 animate-pulse">Loading...</span>
          </div>
        </:loading>

        <%= if @albums != [] do %>
          <div class="bg-surface-10 shadow-lg aspect-square">
            <ol
              id={@id}
              class="grid grid-cols-5 p-1"
              phx-update={is_struct(@albums, Phoenix.LiveView.LiveStream) && "stream"}
            >
              <li
                :for={{dom_id, album} <- @albums}
                id={dom_id}
                class={[
                  "group relative ease-in-out transition-transform duration-300",
                  "hover:scale-110 hover:shadow-xl hover:z-10"
                ]}
              >
                <.image
                  src={album.image}
                  alt={album.name}
                  class="w-full h-auto transition group-hover:brightness-40 group-hover:rounded-xs"
                  width={164}
                  height={164}
                  loading="lazy"
                />
                <div class="absolute inset-0 rounded-md overflow-hidden p-1">
                  <div class="flex h-full items-end justify-start text-white transition-opacity opacity-0 group-hover:opacity-100 duration-300">
                    <div class="flex flex-col">
                      <div class="font-medium text-sm line-clamp-1 text-ellipsis">
                        <a href={album.url} target="_blank" class="text-white" title={album.name}>
                          {album.name}
                        </a>
                      </div>
                      <div class="text-neutral-200 text-xs line-clamp-1 text-ellipsis">
                        {album.artist}
                      </div>
                      <div class="text-neutral-300 text-xs line-clamp-1 text-ellipsis">
                        {Support.format_number(album.playcount, 0)} plays
                      </div>
                    </div>
                  </div>
                </div>
              </li>
            </ol>
          </div>
        <% else %>
          <div class="flex items-center">
            <.icon name="hero-bolt-slash-solid" class="mt-2 size-6 text-content-40/20" />
          </div>
        <% end %>
      </.async_result>
    </div>
    """
  end

  @doc false

  attr :id, :string, default: "books-list"
  attr :async, AsyncResult, required: true
  attr :books, :list, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def books_list(assigns) do
    ~H"""
    <div class={@class} {@rest}>
      <.async_result :let={_async} assign={@async}>
        <:loading>
          <span class="font-medium text-content-40/50 animate-pulse">Loading...</span>
        </:loading>

        <%= if @books != [] do %>
          <ul
            id={@id}
            class="flex flex-col gap-4"
            phx-update={is_struct(@books, Phoenix.LiveView.LiveStream) && "stream"}
          >
            <li :for={{dom_id, book} <- @books} id={dom_id} class="flex flex-row gap-4">
              <a
                href={book.url}
                target="_blank"
                class="group relative shrink-0 rounded-md border-2 border-transparent hover:border-secondary transition-border"
              >
                <div class={[
                  "absolute inset-0 rounded-sm bg-secondary/25 opacity-0 transition-opacity",
                  "group-hover:opacity-100"
                ]}>
                  <.icon
                    name="hero-arrow-top-right-on-square"
                    class="size-10 text-white absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 opacity-90"
                  />
                </div>
                <.image
                  src={book.cover_url}
                  alt={"#{book.title} cover by #{book.author}"}
                  class="object-cover rounded-sm shadow-sm"
                  width={110}
                  height={220}
                  loading="lazy"
                />
              </a>
              <div class="max-w-md flex justify-center items-center">
                <div class="flex flex-col gap-0.5">
                  <div class="line-clamp-2 text-ellipsis text-balance">
                    <a
                      href={book.url}
                      target="_blank"
                      class="link-subtle font-headings font-medium text-xl text-content-20"
                    >
                      {book.title}
                    </a>
                  </div>
                  <div class="line-clamp-1 text-ellipsis">
                    <a
                      href={book.author_url}
                      target="_blank"
                      class="link-ghost font-light text-xl text-content-30"
                    >
                      {book.author}
                    </a>
                  </div>
                  <%= if book.pub_date do %>
                    <div class="line-clamp-1 font-light text-ellipsis text-base text-content-40">
                      {format_date(book.pub_date, "%Y")}
                    </div>
                  <% else %>
                    <div class="font-light text-ellipsis text-base text-content-40/50">
                      Unknown
                    </div>
                  <% end %>
                </div>
              </div>
            </li>
          </ul>
        <% else %>
          <div class="flex items-center">
            <.icon name="hero-bolt-slash-solid" class="mt-2 size-6 text-content-40/20" />
          </div>
        <% end %>
      </.async_result>
    </div>
    """
  end

  @doc false

  attr :id, :string, default: "recent-games-list"
  attr :async, AsyncResult, required: true
  attr :games, :list, required: true
  attr :img_width, :integer, default: 160
  attr :class, :string, default: nil
  attr :rest, :global

  def recent_games(assigns) do
    ~H"""
    <div class={@class} {@rest}>
      <.async_result :let={_async} assign={@async}>
        <:loading>
          <div class="flex flex-col items-center gap-2">
            <.icon name="lucide-loader-circle" class="mt-8 size-6 text-content-40/20 animate-spin" />
            <span class="font-medium text-content-40/50 animate-pulse">Loading...</span>
          </div>
        </:loading>

        <:failed :let={_failure}>
          <div class="flex flex-col items-center gap-2">
            <.icon name="lucide-zap-off" class="mt-8 size-6 text-content-40/20" />
            <span class="text-content-40/50">Failed to load favourite games</span>
          </div>
        </:failed>

        <%= if @games != [] do %>
          <ul
            id={@id}
            class="flex flex-wrap gap-4"
            phx-update={is_struct(@games, Phoenix.LiveView.LiveStream) && "stream"}
          >
            <li
              :for={{dom_id, game} <- @games}
              id={dom_id}
              class="w-full sm:w-auto flex flex-row gap-4"
            >
              <a
                href={game.store_url}
                target="_blank"
                class="group relative w-full sm:w-auto sm:shrink-0 rounded-md border-2 border-transparent hover:border-secondary transition-border"
              >
                <div class={[
                  "absolute inset-0 rounded-sm bg-secondary/25 opacity-0 transition-opacity",
                  "group-hover:opacity-100"
                ]}>
                  <.icon
                    name="hero-arrow-top-right-on-square"
                    class="size-10 text-white absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 opacity-90"
                  />
                </div>

                <.image
                  src={game.thumbnail_url}
                  alt={"#{game.name} game cover"}
                  class="hidden sm:block object-cover rounded-sm shadow-sm"
                  width={@img_width}
                  height={@img_width * 1.5}
                  loading="lazy"
                />

                <.image
                  src={game.header_url}
                  alt={"#{game.name} game cover"}
                  class="w-full sm:hidden object-cover rounded-sm shadow-sm"
                  width={460}
                  height={215}
                  loading="lazy"
                />
              </a>
            </li>
          </ul>
        <% else %>
          <div class="flex items-center">
            <.icon name="hero-bolt-slash-solid" class="mt-2 size-6 text-content-40/20" />
          </div>
        <% end %>
      </.async_result>
    </div>
    """
  end

  @doc false

  attr :id, :string, default: "favourite-games-list"
  attr :async, AsyncResult, required: true
  attr :games, :list, required: true
  attr :img_width, :integer, default: 160
  attr :class, :string, default: nil
  attr :rest, :global

  def favourite_games(assigns) do
    ~H"""
    <div class={@class} {@rest}>
      <.async_result :let={_async} assign={@async}>
        <:loading>
          <div class="flex flex-col items-center gap-2">
            <.icon name="lucide-loader-circle" class="mt-8 size-6 text-content-40/20 animate-spin" />
            <span class="font-medium text-content-40/50 animate-pulse">Loading...</span>
          </div>
        </:loading>

        <:failed :let={_failure}>
          <div class="flex flex-col items-center gap-2">
            <.icon name="lucide-zap-off" class="mt-8 size-6 text-content-40/20" />
            <span class="text-content-40/50">Failed to load favourite games</span>
          </div>
        </:failed>

        <%= if @games != [] do %>
          <ul
            id={@id}
            class="grid grid-cols1 sm:grid-cols-2 lg:grid-cols-3 gap-4"
            phx-update={is_struct(@games, Phoenix.LiveView.LiveStream) && "stream"}
          >
            <li
              :for={{dom_id, game} <- @games}
              id={dom_id}
              class="w-full md:w-auto flex flex-row gap-4"
            >
              <a
                href={game.store_url}
                target="_blank"
                class="group relative w-full md:w-auto rounded-md border-2 border-transparent hover:border-secondary transition-border"
              >
                <div class={[
                  "absolute inset-0 rounded-sm bg-secondary/25 opacity-0 transition-opacity",
                  "group-hover:opacity-100"
                ]}>
                  <.icon
                    name="hero-arrow-top-right-on-square"
                    class="size-10 text-white absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 opacity-90"
                  />
                </div>

                <.image
                  src={game.header_url}
                  alt={"#{game.name} game cover"}
                  class="w-full md:w-84 object-cover rounded-sm shadow-sm"
                  width={460}
                  height={215}
                  loading="lazy"
                />
              </a>
            </li>
          </ul>
        <% else %>
          <div class="flex items-center">
            <.icon name="hero-bolt-slash-solid" class="mt-2 size-6 text-content-40/20" />
          </div>
        <% end %>
      </.async_result>
    </div>
    """
  end

  ## Renderless Helpers

  # Shortened date string, e.g. "2023-10-01" -> "Oct 2023"
  defp parse_date(nil), do: "Present"

  defp parse_date(string) do
    case Date.from_iso8601(string) do
      {:ok, date} -> Calendar.strftime(date, "%b %Y")
      {:error, _} -> nil
    end
  end

  defp format_date(date, format)

  defp format_date(nil, _), do: nil

  defp format_date(%Date{} = date, format) do
    Calendar.strftime(date, format)
  end
end
