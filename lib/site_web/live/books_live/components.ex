defmodule SiteWeb.BooksLive.Components do
  use SiteWeb, :html

  alias Phoenix.LiveView.AsyncResult
  alias SiteWeb.Helpers

  @doc false

  attr :id, :string, default: "books-reading-list"
  attr :async, AsyncResult, required: true
  attr :books, :list, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def reading_list(assigns) do
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
                      class="link-ghost font-light text-xl text-content-40"
                    >
                      {book.author}
                    </a>
                  </div>
                  <%= if book.pub_date do %>
                    <div class="line-clamp-1 font-light text-ellipsis text-base text-content-40">
                      {Helpers.format_date(book.pub_date, "%Y")}
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

  attr :id, :string, default: "books-read-list"
  attr :async, AsyncResult, required: true
  attr :books, :list, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def read_list(assigns) do
    ~H"""
    <div class={@class} {@rest}>
      <.async_result :let={_async} assign={@async}>
        <:loading>
          <span class="font-medium text-content-40/50 animate-pulse">Loading...</span>
        </:loading>

        <.table id="recent-books" class="text-sm" rows={@books}>
          <:col
            :let={{_id, book}}
            label="Title"
            head_class="text-left"
            class="w-full text-left"
          >
            <span class="block truncate max-w-[72ch]">
              <.link href={book.url} target="_blank" rel="noreferrer">{book.title}</.link>
            </span>
          </:col>
          <:col
            :let={{_id, book}}
            label="Author"
            head_class="text-left"
            class="text-left whitespace-nowrap text-content-20"
          >
            {book.author}
          </:col>
          <:col
            :let={{_id, book}}
            label="Date"
            head_class="text-left"
            class="text-left whitespace-nowrap text-content-20"
          >
            {format_read_date(book.read_date)}
          </:col>
        </.table>
      </.async_result>
    </div>
    """
  end

  defp format_read_date(nil), do: "Unknown"

  defp format_read_date(%Date{} = date) do
    Helpers.format_date(date, "%b %Y")
  end
end
