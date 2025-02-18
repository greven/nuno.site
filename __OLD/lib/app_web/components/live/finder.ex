defmodule AppWeb.Finder do
  @moduledoc """
  A finder / command palette that provides search and navigation functionality to the website.

  This is the entry point that coordinates the calls
  to the LiveView and the LiveComponent.
  """

  use AppWeb, :verified_routes
  import Phoenix.LiveView

  alias Phoenix.LiveView.JS
  alias AppWeb.FinderLive

  @commands [
    {:nav_home, name: "Home", description: "Go Home", icon: "heroicons:home"},
    {:nav_about, name: "About", description: "About me", icon: "heroicons:user-circle"},
    {:nav_music, name: "Music", description: "My Music", icon: "heroicons:musical-note"}
  ]

  defmacro __using__(_opts) do
    quote do
      on_mount {AppWeb.FinderLive, :default}
    end
  end

  def list_commands(:global, _query), do: @commands

  ## Handle commands
  def handle_command(:nav_home, _context, socket), do: push_navigate(socket, to: ~p"/")
  def handle_command(:nav_about, _context, socket), do: push_navigate(socket, to: ~p"/about")
  def handle_command(:nav_music, _context, socket), do: push_navigate(socket, to: ~p"/music")

  ## Deletgates

  defdelegate open(js \\ %JS{}), to: FinderLive
  defdelegate close(js \\ %JS{}), to: FinderLive
  defdelegate toggle(js \\ %JS{}), to: FinderLive
  defdelegate exec(js \\ %JS{}, id), to: FinderLive

  defdelegate send_open(), to: FinderLive
  defdelegate send_close(), to: FinderLive
  defdelegate send_toggle(), to: FinderLive
  defdelegate send_exec(id, context), to: FinderLive
end
