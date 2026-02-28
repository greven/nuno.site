defmodule Site.BCD.Repo do
  @moduledoc """
  Dedicated Ecto repo for the MDN Browser Compatibility Data SQLite database.
  Configured dynamically at startup.
  """

  use Ecto.Repo,
    otp_app: :site,
    adapter: Ecto.Adapters.SQLite3
end
