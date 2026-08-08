defmodule SiteWeb.PhotosLive.Components do
  @moduledoc """
  Reusable components for the photography gallery.
  """

  use SiteWeb, :html

  alias Site.Gallery

  @doc """
  Page header with controls.
  """

  attr :title, :string, required: true
  attr :subtitle, :string, required: true
  attr :form, Phoenix.HTML.Form, required: true
  attr :rest, :global

  def photo_page_header(assigns) do
    ~H"""
    <header {@rest}>
      <div class="relative flex justify-between gap-4">
        <.header underlined>
          {@title}
          <:subtitle>{@subtitle}</:subtitle>
        </.header>

        <div class="mt-2 flex justify-center gap-2">
          <.header_overlay form={@form} />

          <.icon_button variant="ghost" disabled>
            <.icon name="lucide-tag" class="size-6 text-content-40/80" />
          </.icon_button>

          <.icon_button
            variant="ghost"
            phx-click={
              JS.show(
                to: "#header-overlay",
                transition: {"ease-out duration-300", "opacity-0", "opacity-100"}
              )
              |> JS.focus(to: "#header-overlay input")
            }
          >
            <.icon name="lucide-search" class="size-6 text-content-40/80" />
          </.icon_button>
        </div>
      </div>
    </header>
    """
  end

  attr :form, Phoenix.HTML.Form, required: true

  defp header_overlay(assigns) do
    ~H"""
    <div
      id="header-overlay"
      class="hidden absolute -inset-2 bg-surface z-1"
      phx-window-keydown={
        if(@form[:query].value == "",
          do:
            JS.hide(
              to: "#header-overlay",
              transition: {"ease-out duration-300", "opacity-100", "opacity-0"}
            ),
          else: nil
        )
      }
      phx-key="Escape"
    >
      <div class="px-2 py-4 flex gap-4">
        <.form
          for={@form}
          id="photo-search"
          phx-change="search"
          phx-submit="search"
          phx-debounce="300"
          class="flex-1"
        >
          <input
            type="text"
            name="query"
            value={@form[:query].value}
            placeholder="Search photos..."
            phx-change="search"
            phx-debounce="300"
            aria-label="Search photos"
            class={[
              "w-full border-b-2 border-surface-30 text-lg text-content-10",
              "focus:outline-none focus:border-primary",
              "placeholder:text-content-40/60"
            ]}
          />
        </.form>

        <.icon_button
          variant="ghost"
          phx-click={
            JS.push("clear_search")
            |> JS.hide(
              to: "#header-overlay",
              transition: {"ease-out duration-300", "opacity-100", "opacity-0"}
            )
          }
        >
          <.icon name="lucide-x" class="size-6 text-content-40/80" />
        </.icon_button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a grid of photography cards.
  """

  attr :photos, :list, required: true, doc: "list of Photo structs"
  attr :query, :string, default: "", doc: "the active search query"
  attr :id, :string, default: "photo-grid", doc: "the DOM id of the grid container"
  attr :class, :string, default: nil
  attr :rest, :global

  def photo_grid(assigns) do
    ~H"""
    <ul id={@id} class={["grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4", @class]} {@rest}>
      <li
        :if={@photos == []}
        class="col-span-full place-items-center flex items-center justify-center gap-2"
      >
        <%= if String.trim(@query) == "" do %>
          <div class="py-8 flex flex-col items-center justify-center gap-4">
            <.icon name="lucide-frown" class="text-center text-content-40/50" />
            <p class="text-center text-content-40">No photos yet...</p>
          </div>
        <% else %>
          <div class="py-8 flex flex-col items-center justify-center gap-4">
            <.icon name="lucide-search-x" class="size-8 text-center text-content-40/50" />
            <p class="text-center text-content-40">No results for "{@query}"</p>
          </div>
        <% end %>
      </li>

      <.photo_card :for={photo <- @photos} photo={photo} />
    </ul>
    """
  end

  @doc """
  A single photo card with a blurred placeholder loading effect.
  """

  attr :photo, Gallery.Photo, required: true, doc: "the Photo struct"
  attr :size, :integer, default: 300, doc: "the size of the thumbnail in pixels"
  attr :class, :string, default: nil
  attr :rest, :global

  def photo_card(%{photo: photo} = assigns) do
    assigns =
      assigns
      |> assign(:photo_url, "#{Gallery.photo_url(photo.id)}_thumbnail_400w.jpg")

    ~H"""
    <li class="group relative">
      <.image
        src={@photo_url}
        alt={@photo.title || @photo.id}
        width={@size}
        height={@size}
        loading="lazy"
        class="w-full aspect-square object-cover border-4 border-surface-10 dark:border-surface-30 rounded shadow-md"
      />
      <p class={[
        "absolute left-1 right-1 bottom-1 p-1.5 bg-surface-20/80 backdrop-blur-sm text-center text-content-30 text-xs font-medium",
        "line-clamp-1 truncate opacity-0 transition-opacity duration-300 ease-in-out",
        "group-hover:opacity-100"
      ]}>
        {@photo.title}
      </p>
      <.link navigate={~p"/photos/#{@photo}"} class="absolute inset-0 z-10 outline-none"></.link>
    </li>
    """
  end

  @doc """
  Displays a single photo.
  """

  attr :photo, Gallery.Photo, required: true, doc: "the Photo struct"
  attr :prev, Gallery.Photo, default: nil
  attr :next, Gallery.Photo, default: nil

  def photo(assigns) do
    assigns =
      assigns
      |> assign(:photo_url, "#{Gallery.photo_url(assigns.photo.id)}.jpg")

    ~H"""
    <div class="group/photo relative">
      <.image
        src={@photo_url}
        alt={@photo.title || @photo.id}
        width={@photo.width}
        height={@photo.height}
        loading="lazy"
        class="max-w-container object-cover border-4 border-surface-10 rounded shadow-md"
        use_picture
        use_blur
      />

      <.gallery_navigation photo={@photo} prev={@prev} next={@next} />
    </div>
    """
  end

  @doc """
  Displays the photo fullscreen, with a title bar and controls to
  close, show info, and navigate between photos.
  """

  attr :photo, Gallery.Photo, required: true
  attr :prev, Gallery.Photo, default: nil
  attr :next, Gallery.Photo, default: nil
  attr :show, :boolean, default: false, doc: "whether the dialog should stay open"

  def photo_fullscreen_dialog(assigns) do
    assigns =
      assigns
      |> assign(:photo_url, "#{Gallery.photo_url(assigns.photo.id)}.jpg")

    ~H"""
    <.dialog
      show={@show}
      id="photo-fullscreen"
      data-on-close-push="toggle_fullscreen"
      backdrop_class="backdrop:bg-black backdrop:opacity-0 open:backdrop:opacity-100 backdrop:transition-opacity backdrop:duration-300"
      panel_bg_class="bg-transparent"
      panel_shadow_class=""
      panel_outline_class=""
      size="full"
      use_backdrop
      fullscreen
      centered
    >
      <div
        id="photo-fullscreen-view"
        phx-hook="PhotoSwipe"
        data-has-prev={to_string(@prev != nil)}
        data-has-next={to_string(@next != nil)}
        class="relative h-full w-full"
      >
        <%!-- Title bar + controls --%>
        <div class="absolute inset-x-0 top-0 z-20 flex items-start justify-between gap-4 bg-linear-to-b from-black/70 via-black/40 to-transparent p-4 sm:p-6">
          <div class="min-w-0 pt-1">
            <h2
              id="photo-fullscreen-title"
              class="truncate text-lg font-medium text-white drop-shadow-sm"
            >
              {@photo.title || @photo.id}
            </h2>
            <p :if={@photo.album} class="mt-0.5 truncate text-sm text-white/80">
              {@photo.album}
            </p>
          </div>

          <div class="flex shrink-0 items-center gap-2">
            <.fullscreen_control_button
              id="photo-fullscreen-info"
              aria-label="Show photo info"
              title="Info"
              phx-click={JS.dispatch("show-drawer", to: "#photo-info")}
            >
              <.icon name="lucide-info" class="size-5 text-content-20" />
            </.fullscreen_control_button>

            <.fullscreen_control_button
              id="photo-fullscreen-close"
              aria-label="Exit fullscreen"
              title="Exit fullscreen"
              phx-click={JS.push("toggle_fullscreen") |> hide_dialog("#photo-fullscreen")}
            >
              <.icon name="lucide-x" class="size-6 text-content-20" />
            </.fullscreen_control_button>
          </div>
        </div>

        <%!-- Image --%>
        <div class="flex h-full w-full items-center justify-center">
          <.image
            src={@photo_url}
            alt={@photo.title || @photo.id}
            width={@photo.width}
            height={@photo.height}
            class="max-h-full max-w-full object-contain"
            use_picture
            use_blur
          />
        </div>

        <%!-- Navigation arrows, revealed when approaching their edge --%>
        <div :if={@prev} class="group absolute inset-y-0 left-0 z-10 w-20 sm:w-24">
          <.photo_nav_button
            id="photo-fullscreen-prev"
            class="left-4"
            reveal="group-hover:opacity-100 group-focus-within:opacity-100"
            aria-label="Previous photo"
            phx-click={JS.push("navigate", value: %{direction: "prev"})}
          >
            <.icon name="lucide-chevron-left" class="size-7" />
          </.photo_nav_button>
        </div>

        <div :if={@next} class="group absolute inset-y-0 right-0 z-10 w-20 sm:w-24">
          <.photo_nav_button
            id="photo-fullscreen-next"
            class="right-4"
            reveal="group-hover:opacity-100 group-focus-within:opacity-100"
            aria-label="Next photo"
            phx-click={JS.push("navigate", value: %{direction: "next"})}
          >
            <.icon name="lucide-chevron-right" class="size-7" />
          </.photo_nav_button>
        </div>
      </div>
    </.dialog>
    """
  end

  attr :rest, :global
  slot :inner_block, required: true

  defp fullscreen_control_button(assigns) do
    ~H"""
    <button
      type="button"
      class={[
        "flex size-11 cursor-pointer items-center justify-center rounded-full",
        "bg-black/50 text-white backdrop-blur-sm transition-colors",
        "hover:bg-black/70 focus-visible:outline-2",
        "focus-visible:outline-offset-2 focus-visible:outline-white"
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Render a list of the photo tags.
  """

  attr :photo, Gallery.Photo, required: true
  attr :class, :string, default: nil

  def photo_tags(assigns) do
    ~H"""
    <div
      :if={@photo.tags && !Enum.empty?(@photo.tags)}
      class={["flex flex-wrap items-center gap-2", @class]}
    >
      <span :for={tag <- @photo.tags} class="capitalize">
        <span class="text-content-40/80">#</span> <span class="text-content-10">{tag}</span>
      </span>
    </div>
    """
  end

  @doc """
  Displays the details of a photo.
  """

  attr :photo, Gallery.Photo, required: true
  attr :class, :string, default: nil

  def photo_details(assigns) do
    ~H"""
    <div class={["flex flex-col gap-4 text-sm", @class]}>
      <.photo_detail_item :if={@photo.date} icon="lucide-calendar-days">
        <SiteWeb.CoreComponents.date date={@photo.date} />
      </.photo_detail_item>
      <.photo_detail_item :if={@photo.location} icon="lucide-map-pin">
        {@photo.location}
      </.photo_detail_item>
      <.photo_detail_item :if={@photo.camera} icon="lucide-camera">
        {@photo.camera}
      </.photo_detail_item>
    </div>
    """
  end

  attr :icon, :string, required: true
  slot :inner_block, required: true

  defp photo_detail_item(assigns) do
    ~H"""
    <div class="flex items-center gap-2.5">
      <.icon name={@icon} class="size-5 text-content-30" />
      <div class="text-content-20">{render_slot(@inner_block)}</div>
    </div>
    """
  end

  @doc """
  Renders the navigation arrows for the gallery given the current photo.
  """

  attr :photo, Gallery.Photo, required: true
  attr :prev, Gallery.Photo, default: nil
  attr :next, Gallery.Photo, default: nil

  def gallery_navigation(assigns) do
    ~H"""
    <.photo_nav_button
      :if={@prev}
      class="left-4"
      phx-click={JS.push("navigate", value: %{direction: "prev"})}
      phx-window-keydown="navigate"
      phx-value-direction="prev"
      phx-key="ArrowLeft"
    >
      <.icon name="lucide-chevron-left" class="size-7" />
    </.photo_nav_button>

    <.photo_nav_button
      :if={@next}
      class="right-4"
      phx-click={JS.push("navigate", value: %{direction: "next"})}
      phx-window-keydown="navigate"
      phx-value-direction="next"
      phx-key="ArrowRight"
    >
      <.icon name="lucide-chevron-right" class="size-7" />
    </.photo_nav_button>
    """
  end

  attr :class, :string, default: nil

  attr :reveal, :string,
    default: "group-hover/photo:opacity-100",
    doc: "classes that reveal the button (e.g. on hover/focus of a surrounding group)"

  attr :rest, :global

  slot :inner_block, required: true

  defp photo_nav_button(assigns) do
    ~H"""
    <button
      class={[
        "absolute top-1/2 size-12 -translate-y-1/2 rounded-[50%] flex items-center justify-center",
        "bg-surface-10/60 backdrop-blur-sm shadow opacity-1 cursor-pointer z-10",
        "transition-opacity ease-in",
        @reveal,
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end
end
