defmodule SiteWeb.PhotosLive.Components do
  @moduledoc """
  Reusable components for the photography gallery.
  """

  use SiteWeb, :html

  alias Site.Gallery.Photo

  @doc """
  Renders a grid of photo cards.

  ## Examples

      <.photo_grid photos={@photos} />
      <.photo_grid photos={@photos} columns={3} />
  """

  attr :photos, :list, required: true, doc: "list of Photo structs"
  attr :id, :string, default: "photo-grid", doc: "the DOM id of the grid container"
  attr :class, :string, default: nil
  attr :rest, :global

  def photo_grid(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4",
        @class
      ]}
      {@rest}
    >
      <.photo_card :for={photo <- @photos} photo={photo} />
    </div>
    """
  end

  @doc """
  A single photo card with a blurred placeholder loading effect.
  """

  attr :photo, Photo, required: true, doc: "the Photo struct"
  attr :class, :string, default: nil
  attr :rest, :global

  def photo_card(assigns) do
    ~H"""
    <button
      type="button"
      id={"photo-#{@photo.id}"}
      phx-click="open-photo"
      phx-value-id={@photo.id}
      class={[
        "group relative overflow-hidden rounded-lg bg-surface-10 cursor-pointer",
        "focus-visible:outline focus-visible:outline-offset-2 focus-visible:outline-primary",
        @class
      ]}
      {@rest}
    >
      <div class="aspect-[3/2] relative overflow-hidden">
        <img
          src={Site.Gallery.photo_blur_url(@photo.key)}
          alt={@photo.title || @photo.id}
          class="absolute inset-0 w-full h-full object-cover blur-xl scale-110 opacity-60 transition-opacity duration-500"
          aria-hidden="true"
        />
        <img
          src={Site.Gallery.photo_url(@photo.key)}
          alt={@photo.title || @photo.id}
          loading="lazy"
          class="relative w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
          onload="this.previousElementSibling.style.opacity='0'"
          onerror="this.style.display='none'"
        />
      </div>

      <div class="p-3">
        <p :if={@photo.title} class="text-sm font-medium truncate">
          {@photo.title}
        </p>
        <p :if={@photo.description} class="text-xs text-content-40 mt-0.5 line-clamp-2">
          {@photo.description}
        </p>
      </div>
    </button>
    """
  end

  @doc """
  A lightbox overlay for viewing a photo in detail.
  """

  attr :photo, Photo, required: true, doc: "the Photo struct to display"
  attr :show, :boolean, default: false, doc: "whether the lightbox is visible"

  def lightbox(assigns) do
    ~H"""
    <div
      :if={@show and @photo}
      id="photo-lightbox"
      phx-click="close-photo"
      phx-key="escape"
      phx-window-keydown="close-photo"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4"
      role="dialog"
      aria-modal="true"
      aria-label="Photo viewer"
    >
      <button
        type="button"
        phx-click="close-photo"
        class="absolute top-4 right-4 size-10 flex items-center justify-center rounded-full bg-white/10 hover:bg-white/20 text-white transition-colors"
        aria-label="Close"
      >
        <.icon name="hero-x-mark" class="size-6" />
      </button>

      <figure
        class="max-w-5xl max-h-[90vh] flex flex-col items-center"
        phx-click-stop-propagation
      >
        <img
          id={"lightbox-img-#{@photo.id}"}
          src={Site.Gallery.photo_url(@photo.key)}
          alt={@photo.title || @photo.id}
          class="max-w-full max-h-[80vh] object-contain rounded-lg shadow-2xl"
        />

        <figcaption
          :if={@photo.title || @photo.description}
          class="mt-4 text-center text-white/80 max-w-lg"
        >
          <p :if={@photo.title} class="text-lg font-medium">{@photo.title}</p>
          <p :if={@photo.description} class="text-sm text-white/60 mt-1">{@photo.description}</p>
        </figcaption>
      </figure>
    </div>
    """
  end
end
