defmodule SiteWeb.Router do
  use SiteWeb, :router

  use ErrorTracker.Web, :router

  import SiteWeb.UserAuth

  alias SiteWeb.Hooks
  alias SiteWeb.Plugs

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

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :xml do
    plug :accepts, ["xml"]
  end

  scope "/", SiteWeb do
    pipe_through :api

    get "/health", HealthController, :index
  end

  scope "/", SiteWeb do
    pipe_through :browser

    get "/og-image", OGIController, :show

    live_session :default,
      on_mount: [
        {SiteWeb.UserAuth, :mount_current_scope},
        Hooks.Defaults,
        Hooks.ActiveLinks,
        Hooks.Metrics
      ] do
      live "/", HomeLive.Index, :index, metadata: %{prerender: true}
      live "/blog", BlogLive.Index, :index, metadata: %{prerender: true}
      live "/blog/:year/:slug", BlogLive.Show, :show
      live "/archive/year/:year", ArchiveLive.Index, :index
      live "/categories", CategoriesLive.Index, :index, metadata: %{prerender: true}
      live "/category/:category", CategoriesLive.Show, :show
      live "/tags", TagsLive.Index, :index, metadata: %{prerender: true}
      live "/tag/:tag", TagsLive.Show, :show
      live "/changelog", ChangelogLive.Index, :index, metadata: %{prerender: true}
      live "/analytics", AnalyticsLive.Index, :index, metadata: %{prerender: true}
      live "/travel", TravelLive.Index, :index, metadata: %{prerender: true}
      live "/music", MusicLive.Index, :index, metadata: %{prerender: true}
      live "/books", BooksLive.Index, :index, metadata: %{prerender: true}
      live "/gaming", GamingLive.Index, :index, metadata: %{prerender: true}
      live "/photos", PhotosLive.Index, :index, metadata: %{prerender: true}
      live "/bookmarks", BookmarksLive.Index, :index, metadata: %{prerender: true}
      live "/uses", UsesLive.Index, :index, metadata: %{prerender: true}
      live "/about", AboutLive.Index, :index, metadata: %{prerender: true}
      live "/resume", AboutLive.Resume, :show, metadata: %{prerender: true}
      live "/pulse", PulseLive.Index, :index, metadata: %{prerender: true}
      live "/sitemap", SitemapLive.Index, :index, metadata: %{prerender: true}
      live "/sink", KitchenSinkLive.Index, :index, metadata: %{prerender: true}
    end
  end

  scope "/", SiteWeb do
    pipe_through :xml

    get "/sitemap.xml", SitemapController, :index
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
      on_mount: [{SiteWeb.UserAuth, :require_authenticated}, Hooks.ActiveLinks] do
      live "/", AdminLive.Index, :index
    end

    live_dashboard "/dashboard", metrics: SiteWeb.Telemetry
    error_tracker_dashboard("/errors")
  end

  # Authentication

  scope "/admin", SiteWeb do
    pipe_through [:browser_admin]

    live_session :current_user,
      on_mount: [{SiteWeb.UserAuth, :mount_current_scope}, Hooks.ActiveLinks] do
      live "/log-in", AdminLive.Login, :new
      live "/log-in/:token", AdminLive.Confirmation, :new
    end

    post "/log-in", UserSessionController, :create
    delete "/log-out", UserSessionController, :delete
  end
end
