defmodule AppWeb.Stream do
  @moduledoc """
  This module adds additinal functionality to LiveView streams because
  currently one can't for example, delete all items in a stream.

  When this functionality becomes available in LiveView we can delete this module.
  """

  @type socket :: Phoenix.LiveView.Socket.t()

  def insert_all(socket, name, items, opts) when is_list(items) do
    Enum.reduce(items, socket, fn item, socket ->
      Phoenix.LiveView.stream_insert(socket, name, item, opts)
    end)
  end

  def reset(socket, name, items, opts \\ []) when is_list(items) do
    dbg(socket.assigns.streams.posts)

    Enum.reduce(items, socket, fn item, socket ->
      Phoenix.LiveView.stream_delete(socket, name, item)
    end)

    # insert_all(socket, name, items, opts)
  end
end
