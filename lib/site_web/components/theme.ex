defmodule SiteWeb.Theme do
  @moduledoc """
  Theme supporting functions.
  """

  def colors(:theme), do: ~w(primary secondary info success warning danger neutral)

  def colors(:tailwind) do
    ~w(
        red orange amber yellow lime green emerald teal cyan sky
        blue indigo violet purple fuchsia pink rose
        slate gray zinc neutral stone
    )
  end
end
