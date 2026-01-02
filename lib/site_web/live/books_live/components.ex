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
          <div class="min-h-34 font-medium text-content-40/50 animate-pulse">Loading...</div>
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
                <.icon
                  name="hero-bookmark-mini"
                  class="size-6 absolute -top-1 right-1 text-primary"
                />

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
          <div class="flex items-center gap-3">
            <.icon name="lucide-book-dashed" class="size-8 text-content-40/40" />
            <span class="text-lg text-content-40">Currently not reading any books...</span>
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

        <div class="overflow-x-auto -mx-4 px-4 sm:mx-0 sm:px-0">
          <.table id="recent-books" class="w-full text-sm" rows={@books}>
            <:col
              :let={{_id, book}}
              label="Title"
              head_class="max-w-xs sm:max-w-sm md:max-w-md lg:max-w-none text-left"
              class="max-w-xs sm:max-w-sm md:max-w-md lg:max-w-none text-left text-content-10"
            >
              <span class="group flex items-center">
                <.link
                  href={book.url}
                  target="_blank"
                  rel="noreferrer"
                  class="inline-block"
                >
                  <div class="flex flex-col gap-1">
                    <div class="flex gap-0.5 items-center">
                      <div class="max-w-[32ch] sm:max-w-[48ch] md:max-w-[60ch] lg:max-w-[72ch] truncate">
                        {book.title}
                      </div>
                      <.icon
                        name="lucide-arrow-up-right"
                        class="size-4 inline-block ml-1 text-content-40/20 group-hover:text-content-40 transition-colors"
                      />
                    </div>
                    <div class="lg:hidden max-w-[32ch] sm:max-w-[48ch] md:max-w-[60ch] lg:max-w-[72ch] truncate text-content-40">
                      {book.author}
                    </div>
                  </div>
                </.link>
              </span>
            </:col>
            <:col
              :let={{_id, book}}
              label="Author"
              head_class="hidden lg:table-cell text-left"
              class="hidden lg:table-cell text-left whitespace-nowrap text-content-20"
            >
              {book.author}
            </:col>
            <:col
              :let={{_id, book}}
              label="Date"
              head_class="hidden lg:table-cell text-left"
              class="hidden lg:table-cell text-left whitespace-nowrap text-content-40"
            >
              {format_read_date(book.read_date)}
            </:col>
          </.table>
        </div>
      </.async_result>
    </div>
    """
  end

  @doc false

  attr :id, :string, default: "books-want-list"
  attr :async, AsyncResult, required: true
  attr :books, :list, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def want_to_read_list(assigns) do
    ~H"""
    <div class={@class} {@rest}>
      <.async_result :let={_async} assign={@async}>
        <:loading>
          <span class="font-medium text-content-40/50 animate-pulse">Loading...</span>
        </:loading>
      </.async_result>

      <%= if @books != [] do %>
        <div
          id="want-to-read-list"
          class="flex gap-8 snap-x snap-proximity overflow-x-auto pb-2 -mx-4 px-4 sm:mx-0 sm:px-0"
          phx-update={is_struct(@books, Phoenix.LiveView.LiveStream) && "stream"}
        >
          <div
            :for={{dom_id, book} <- @books}
            id={dom_id}
            class="pb-4 shrink-0 flex items-end snap-center"
          >
            <a
              href={book.url}
              target="_blank"
              class="group inline-block relative rounded-md border-2 border-transparent hover:border-secondary transition-border"
              title={"#{book.title} by #{book.author}"}
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
                class="object-fill rounded-sm shadow-sm"
                width={120}
                height={200}
                loading="lazy"
              />
            </a>
          </div>
        </div>
      <% else %>
        <div class="flex items-center gap-3">
          <.icon name="lucide-book-dashed" class="size-8 text-content-40/40" />
          <span class="text-lg text-content-40">Empty Want to Read list...</span>
        </div>
      <% end %>
    </div>
    """
  end

  defp format_read_date(nil), do: "Unknown"

  defp format_read_date(%Date{} = date) do
    Helpers.format_date(date, "%b %Y")
  end
end
