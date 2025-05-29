defmodule SiteWeb.Router do
  use SiteWeb, :router

  alias SiteWeb.Plugs
  alias SiteWeb.Hooks

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SiteWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Plugs.ActiveLinks
    plug Plugs.BumpMetric
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SiteWeb do
    pipe_through :browser

    get "/about", PageController, :about
    get "/stack", PageController, :stack
    get "/resume", PageController, :resume
    get "/photos", PageController, :photos
    get "/sitemap", PageController, :sitemap
    get "/sink", PageController, :sink

    live_session :default,
      on_mount: [Hooks.ActiveLinks, Hooks.Metrics] do
      live "/", HomeLive.Index, :index
      live "/updates", UpdatesLive.Index, :index
      live "/updates/year/:year", UpdatesLive.Show, :show
      live "/articles", BlogLive.Index, :index
      live "/articles/:year/:slug", BlogLive.Show, :show
      live "/categories", CategoriesLive.Index, :index
      live "/category/:category", CategoriesLive.Show, :show
      live "/tags", TagsLive.Index, :index
      live "/tag/:tag", TagsLive.Show, :show
      live "/travel", TravelLive.Index, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", SiteWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:site, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SiteWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
