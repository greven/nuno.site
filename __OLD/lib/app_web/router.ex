defmodule AppWeb.Router do
  use AppWeb, :router

  import Phoenix.LiveDashboard.Router
  import AppWeb.UserAuth
  import AppWeb.AdminAuth

  alias AppWeb.Plugs

  # https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
  @content_security_policy "style-src 'self' 'unsafe-inline'; script-src 'self' blob:; connect-src 'self' *.nuno.site wss: ws:;"

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers, %{"content-security-policy" => @content_security_policy}
    plug :fetch_current_user
    plug Plugs.Defaults
    plug Plugs.BumpMetric
  end

  pipeline :robots do
    plug :accepts, ~w[json txt xml webmanifest]
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AppWeb, log: false do
    pipe_through [:robots]
    # TODO: SEO stuff
  end

  scope "/", AppWeb do
    pipe_through :browser

    # live_session :default, on_mount: [{AppWeb.UserAuth, :mount_current_user}, AppWeb.Hooks.Links] do
    live_session :default do
      # live "/", HomeLive, :index
      # live "/about", AboutLive, :index
      # live "/stats", StatsLive, :index
      # live "/music", MusicLive, :index
      # live "/books", BooksLive, :index
      # live "/games", GamesLive, :index
      # live "/updates", UpdatesLive, :index
      # live "/writing", BlogLive, :index, as: :blog
      # live "/writing/:id", BlogPostLive, :show, as: :blog
      # live "/writing/tags", TagsLive, :index
      # live "/writing/tags/:tag", TagsLive, :show
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", AppWeb do
  #   pipe_through :api
  # end

  ## Authentication routes

  scope "/", AppWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{AppWeb.UserAuth, :redirect_if_user_is_authenticated}, AppWeb.Hooks.Links] do
      live "/users/log_in", UserLoginLive, :new
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", AppWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
  end

  scope "/admin", AppWeb do
    pipe_through [:browser, :require_admin_user]

    live_session :admin,
      layout: {AppWeb.Layouts, :admin},
      on_mount: [AppWeb.AdminAuth, AppWeb.Scope, AppWeb.Hooks.Links] do
      live "/", AdminLive, :index
      live "/posts", AdminPostsLive, :index
      live "/posts/new", AdminPostsLive, :new
      live "/posts/:slug", AdminPostsLive, :show
    end

    live_dashboard "/dashboard", metrics: AppWeb.Telemetry
  end

  # Development only routes
  if Application.compile_env(:app, :dev_routes) do
    scope "/dev", AppWeb do
      pipe_through [:browser]

      get "/spotify", SpotifyController, :index
      get "/spotify/callback", SpotifyController, :callback

      # TODO: https://nuno.site/lastfm/callback
    end
  end
end
