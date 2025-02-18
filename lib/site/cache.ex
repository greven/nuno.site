defmodule Site.Cache do
  @moduledoc false

  use Nebulex.Cache,
    otp_app: :site,
    adapter: Nebulex.Adapters.Local
end
