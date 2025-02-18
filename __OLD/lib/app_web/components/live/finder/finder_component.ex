defmodule AppWeb.FinderComponent do
  @moduledoc """
  A finder / command palette that provides search and navigation functionality to the website.
  """

  use AppWeb, :live_component

  alias AppWeb.Finder

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-window-keydown="keydown" phx-key="k" phx-throttle="400" phx-target={@myself}>
      <.modal
        :if={@show}
        id="finder-modal"
        on_cancel={JS.push("toggle_finder", target: @myself)}
        show_close_button={false}
        modal_class="w-full max-w-xl p-4 sm:p-6 lg:py-8"
        wrapper_class="rounded-xl bg-white shadow-lg shadow-neutral-700/10 transition"
        show
      >
        <.form
          :let={f}
          id="finder-content"
          for={%{}}
          as={:command}
          phx-change="change"
          phx-submit="submit"
          phx-target={@myself}
        >
          <div class="relative divide-y divide-gray-100">
            <.icon
              name="heroicons:magnifying-glass-mini"
              class="absolute left-4 top-3.5 h-5 w-5 text-neutral-400 pointer-events-none"
            />
            <input
              class="h-12 w-full pl-11 px-4 py-2.5 rounded-md bg-transparent border-0 placeholder:text-neutral-500 text-neutral-900 sm:text-sm focus:outline-none focus:ring-0"
              id={f[:input].id}
              name={f[:input].name}
              value={f[:input].value}
              phx-keydown="keydown"
              phx-target={@myself}
              autocomplete="off"
              placeholder="Search..."
              role="combobox"
              aria-expanded="false"
              aria-controls="options"
            />
          </div>
        </.form>

        <ul
          class="max-h-72 scroll-py-2 overflow-y-auto py-2 text-sm text-neutral-800"
          id="options"
          role="listbox"
        >
          <li
            :for={{{id, opts}, index} <- Enum.with_index(Enum.take(@commands, 10))}
            class={[
              if(@selected_index == index, do: "bg-neutral-100"),
              "cursor-pointer select-none rounded-md flex items-center px-4 py-2 hover:bg-neutral-100"
            ]}
            phx-click={Finder.exec(id)}
            role="option"
            tabindex="-1"
          >
            <.icon name={opts[:icon]} class="h-5 w-5 mr-2 text-neutral-600" />

            {Keyword.fetch!(opts, :name)}
          </li>
        </ul>
      </.modal>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_commands()

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_finder", _payload, socket) do
    Finder.send_toggle()
    {:noreply, socket}
  end

  @impl true
  def handle_event("keydown", params, socket) do
    case params do
      %{"key" => "k", "metaKey" => true, "repeat" => false} ->
        Finder.send_toggle()
        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("change", %{"command" => %{"input" => query}}, socket) do
    IO.inspect(query)
    {:noreply, assign_commands(socket, query)}
  end

  def handle_event("submit", %{"command" => %{"input" => query}}, socket) do
    IO.inspect(query)
    {:noreply, socket}
  end

  defp assign_commands(socket, query \\ "") do
    has_local_commands? = function_exported?(socket.view, :list_commands, 2)

    commands =
      if has_local_commands? do
        socket.view.list_commands(socket.assigns[:finder_context], query) ++
          Finder.list_commands(:global, query)
      else
        Finder.list_commands(:global, query)
      end
      |> filter_commands(query)

    socket
    |> assign(:commands, commands)
    |> assign(:selected_index, 0)
  end

  defp filter_commands(commands, query) do
    normalize = &String.downcase(String.replace(&1, ~r/\s/, ""))
    Enum.filter(commands, fn {_id, opts} -> normalize.(opts[:name]) =~ normalize.(query) end)
  end
end
