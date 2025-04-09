defmodule SiteWeb.FinderLive do
  @doc """
  LiveView functionality for the finder that attaches hooks to the socket.
  This module is haavily based on the `command_k` hex package.
  """

  import Phoenix.LiveView
  # import Phoenix.Component

  # alias Phoenix.LiveView.JS

  # alias SiteWeb.Finder

  def on_mount(:default, _params, _session, socket) do
    # socket =
    #   socket
    #   |> assign(show_finder: false)
    #   |> assign(finder_context: %{})
    #   |> attach_hook(:__finder_event__, :handle_event, &handle_finder_event/3)
    #   |> attach_hook(:__finder_info__, :handle_info, &handle_finder_info/2)

    {:cont, socket}
  end

  ## Events

  # def open(js \\ %JS{}), do: JS.push(js, "finder:open")
  # def close(js \\ %JS{}), do: JS.push(js, "finder:close")
  # def toggle(js \\ %JS{}), do: JS.push(js, "finder:toggle")
  # def exec(js \\ %JS{}, id), do: JS.push(js, "finder:exec", value: %{command_id: id})

  # defp handle_finder_event("finder:" <> event, params, socket) do
  #   case {event, params} do
  #     {"open", _} ->
  #       {:halt, do_open(socket)}

  #     {"close", _} ->
  #       {:halt, do_close(socket)}

  #     {"toggle", _} ->
  #       {:halt, do_toggle(socket)}

  #     {"exec", %{"command_id" => id}} ->
  #       id = String.to_existing_atom(id)
  #       context = socket.assigns[:finder_context]
  #       {:halt, do_exec(socket, id, context)}

  #     _ ->
  #       {:halt, socket}
  #   end
  # end

  # defp handle_finder_event(_event, _params, socket), do: {:cont, socket}

  # ## Messages

  # def send_open(), do: send(self(), {:finder, :open})
  # def send_close(), do: send(self(), {:finder, :close})
  # def send_toggle(), do: send(self(), {:finder, :toggle})
  # def send_exec(id, context), do: send(self(), {:finder, {:exec, id, context}})

  # defp handle_finder_info({:finder, message}, socket) do
  #   case message do
  #     :open ->
  #       {:halt, do_open(socket)}

  #     :close ->
  #       {:halt, do_close(socket)}

  #     :toggle ->
  #       {:halt, do_toggle(socket)}

  #     {:exec, id, context} ->
  #       {:halt, do_exec(socket, id, context)}
  #   end
  # end

  # defp handle_finder_info(_info, socket), do: {:cont, socket}

  # defp do_open(socket), do: assign(socket, :show_finder, true)
  # defp do_close(socket), do: assign(socket, :show_finder, false)
  # defp do_toggle(socket), do: update(socket, :show_finder, &(not &1))

  # defp do_exec(socket, id, context) do
  #   Finder.handle_command(id, context, socket) |> do_close()
  # end
end
