defmodule SiteWeb.Router do
  use SiteWeb, :router

  import SiteWeb.UserAuth

  alias SiteWeb.Plugs
  alias SiteWeb.Hooks

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SiteWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
    plug Plugs.ActiveLinks
    plug Plugs.BumpMetric
  end

  pipeline :browser_admin do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SiteWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :rss do
    plug :accepts, ["xml"]
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SiteWeb do
    pipe_through :browser

    live_session :default,
      on_mount: [
        {SiteWeb.UserAuth, :mount_current_scope},
        Hooks.ActiveLinks,
        Hooks.Metrics
      ] do
      live "/", HomeLive.Index, :index
      live "/updates", UpdatesLive.Index, :index
      live "/articles", BlogLive.Index, :index
      live "/articles/:year/:slug", BlogLive.Show, :show
      live "/archive/year/:year", ArchiveLive.Index, :index
      live "/categories", CategoriesLive.Index, :index
      live "/category/:category", CategoriesLive.Show, :show
      live "/tags", TagsLive.Index, :index
      live "/tag/:tag", TagsLive.Show, :show
      live "/analytics", AnalyticsLive.Index, :index
      live "/travel", TravelLive.Index, :index
      live "/music", MusicLive.Index, :index
      live "/books", BooksLive.Index, :index
      live "/gaming", GamingLive.Index, :index
      live "/photos", PhotosLive.Index, :index
      live "/bookmarks", BookmarksLive.Index, :index
      live "/stack", StackLive.Index, :index
      live "/about", AboutLive.Index, :index
      live "/resume", AboutLive.Resume, :show
      live "/sitemap", SitemapLive.Index, :index
      live "/sink", KitchenSinkLive.Index, :index
    end
  end

  scope "/", SiteWeb do
    pipe_through :rss
    get "/rss", RssController, :feed
  end

  # Other scopes may use custom stacks.
  # scope "/api", SiteWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:site, :dev_routes) do
    scope "/dev" do
      pipe_through :browser

      get "/spotify", SiteWeb.SpotifyController, :index
      get "/spotify/callback", SiteWeb.SpotifyController, :callback

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Admin routes

  scope "/admin", SiteWeb do
    import Phoenix.LiveDashboard.Router

    pipe_through [:browser_admin, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{SiteWeb.UserAuth, :require_authenticated}] do
      live "/", AdminLive.Index, :index
    end

    live_dashboard "/dashboard", metrics: SiteWeb.Telemetry
  end

  # Authentication

  scope "/admin", SiteWeb do
    pipe_through [:browser_admin]

    live_session :current_user,
      on_mount: [{SiteWeb.UserAuth, :mount_current_scope}] do
      live "/log-in", AdminLive.Login, :new
      live "/log-in/:token", AdminLive.Confirmation, :new
    end

    post "/log-in", UserSessionController, :create
    delete "/log-out", UserSessionController, :delete
  end
end
