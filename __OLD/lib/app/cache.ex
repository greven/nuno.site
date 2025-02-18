defmodule App.Cache do
  @moduledoc false

  use Nebulex.Cache,
    otp_app: :app,
    adapter: Nebulex.Adapters.Local
end
