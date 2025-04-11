defmodule Site.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SiteWeb.Telemetry,
      Site.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:site, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:site, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Site.PubSub},
      # Start Phoenix Presence
      SiteWeb.Presence,
      # Nebulex Cache adapter
      Site.Cache,
      # Site analytics
      Site.Analytics,
      # Start to serve requests, typically the last entry
      SiteWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Site.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SiteWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") == nil
  end
end
