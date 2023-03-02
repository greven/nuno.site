defmodule AppWeb.Router do
  use AppWeb, :router

  import Phoenix.LiveDashboard.Router

  alias AppWeb.Plugs

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {AppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Plugs.BumpMetric
  end

  pipeline :robots do
    plug :accepts, ~w[json txt xml webmanifest]
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :require_auth do
    plug Plugs.CheckAuth
  end

  scope "/", AppWeb do
    pipe_through :browser

    live_session :default do
      live "/", PageLive, :home
      live "/blog", BlogLive, :index, as: :blog
      live "/blog/:slug", BlogLive, :show, as: :blog
      live "/blog/tags", TagsLive, :index
      live "/blog/tags/:tag", TagsLive, :show
      live "/stats", StatsLive, :show
    end
  end

  scope "/", AppWeb, log: false do
    pipe_through [:robots]
  end

  scope "/admin" do
    pipe_through [:browser, :require_auth]

    live_dashboard "/dashboard", metrics: AppWeb.Telemetry
  end

  # Other scopes may use custom stacks.
  # scope "/api", AppWeb do
  #   pipe_through :api
  # end
end
