defmodule SiteWeb.Finder do
  @moduledoc """
  Finder entry point that coordinates the calls
  to the LiveView and the LiveComponent.

  See also the `SiteWeb.SiteComponents` `finder/1` function
  for the UI implementation.gv
  """

  use SiteWeb, :verified_routes
  import Phoenix.LiveView

  alias Phoenix.LiveView.JS

  @finder_id "finder-component"

  @doc """
  List all available commands for the finder.
  It returns a list of items where each item represents a section.
  Each section item contains a title and a list of commands.
  """
  def list_commands do
    [commands(:navigation)]
  end

  defp commands(:navigation) do
    %{
      id: "navigation",
      title: "Navigation",
      commands: [
        {:nav_home, name: "Home", description: "Go Home", icon: "lucide-house", push: true},
        {:nav_blog,
         name: "Blog", description: "Articles and notes", icon: "lucide-notebook-pen", push: true},
        {:nav_about,
         name: "About", description: "About me", icon: "lucide-fingerprint-pattern", push: true},
        {:nav_pulse,
         name: "Pulse", description: "News Pulse", icon: "lucide-activity", push: true},
        {:nav_music,
         name: "Music", description: "Recent music", icon: "lucide-music-4", push: true},
        {:nav_books,
         name: "Books", description: "Currently reading", icon: "lucide-book", push: true},
        {:nav_gaming,
         name: "Gaming", description: "Games I'm playing", icon: "lucide-gamepad-2", push: true},
        {:nav_resume,
         name: "Resume", description: "My Resume", icon: "lucide-file-user", push: true},
        {:nav_photos, name: "Photos", description: "My photos", icon: "lucide-image", push: true},
        {:nav_travel,
         name: "Travel", description: "Travel log", icon: "lucide-map-pinned", push: true},
        {:nav_stack,
         name: "Stack", description: "My stack / tools I use", icon: "lucide-layers", push: true},
        {:nav_bookmarks,
         name: "Bookmarks", description: "My bookmarks", icon: "lucide-bookmark", push: true},
        {:nav_changelog,
         name: "Changelog", description: "Site updates", icon: "lucide-history", push: true}
      ]
    }
  end

  ## JS commands to control the finder component
  def open(js \\ %JS{}), do: JS.dispatch(js, "phx:finder-open", to: "##{@finder_id}")
  def close(js \\ %JS{}), do: JS.dispatch(js, "phx:finder-close", to: "##{@finder_id}")
  def toggle(js \\ %JS{}), do: JS.dispatch(js, "phx:finder-toggle", to: "##{@finder_id}")

  def exec(js \\ %JS{}, command_id) do
    opts = [value: %{command_id: command_id}, target: "##{@finder_id}"]
    JS.push(js, "finder:exec", opts)
  end

  ## Handle commands
  def handle_command(:nav_home, socket), do: push_navigate(socket, to: ~p"/")
  def handle_command(:nav_blog, socket), do: push_navigate(socket, to: ~p"/blog")
  def handle_command(:nav_about, socket), do: push_navigate(socket, to: ~p"/about")
  def handle_command(:nav_pulse, socket), do: push_navigate(socket, to: ~p"/pulse")
  def handle_command(:nav_music, socket), do: push_navigate(socket, to: ~p"/music")
  def handle_command(:nav_books, socket), do: push_navigate(socket, to: ~p"/books")
  def handle_command(:nav_gaming, socket), do: push_navigate(socket, to: ~p"/gaming")
  def handle_command(:nav_resume, socket), do: push_navigate(socket, to: ~p"/resume")
  def handle_command(:nav_photos, socket), do: push_navigate(socket, to: ~p"/photos")
  def handle_command(:nav_travel, socket), do: push_navigate(socket, to: ~p"/travel")
  def handle_command(:nav_stack, socket), do: push_navigate(socket, to: ~p"/uses")
  def handle_command(:nav_bookmarks, socket), do: push_navigate(socket, to: ~p"/bookmarks")
  def handle_command(:nav_changelog, socket), do: push_navigate(socket, to: ~p"/changelog")
end
