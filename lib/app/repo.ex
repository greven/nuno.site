defmodule App.Repo do
  use Ecto.Repo,
    otp_app: :ns,
    adapter: Ecto.Adapters.SQLite3
end
