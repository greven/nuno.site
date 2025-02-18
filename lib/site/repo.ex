defmodule Site.Repo do
  use Ecto.Repo,
    otp_app: :site,
    adapter: Ecto.Adapters.SQLite3
end
