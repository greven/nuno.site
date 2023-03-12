defmodule AppWeb.Router do
  use AppWeb, :router

  import Phoenix.LiveDashboard.Router
  import AppWeb.UserAuth

  alias AppWeb.Plugs

  # https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
  # https://cheatsheetseries.owasp.org/cheatsheets/Content_Security_Policy_Cheat_Sheet.html
  @content_security_policy "default-src 'self'; img-src 'self' data: blob:; style-src 'self' 'unsafe-inline'; script-src 'self' blob:; connect-src 'self' *.nuno.site wss: ws:;"

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {AppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers, %{"content-security-policy" => @content_security_policy}
    plug :fetch_current_user
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
  end

  scope "/", AppWeb do
    pipe_through :browser

    live_session :default,
      on_mount: [{AppWeb.UserAuth, :mount_current_user}, AppWeb.Hooks.ActiveLink] do
      live "/", PageLive, :home
      live "/about", PageLive, :about
      live "/writing", BlogLive, :index, as: :blog
      live "/writing/:slug", BlogLive, :show, as: :blog
      live "/writing/tags", TagsLive, :index
      live "/writing/tags/:tag", TagsLive, :show
      live "/stats", StatsLive, :show
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
      on_mount: [{AppWeb.UserAuth, :redirect_if_user_is_authenticated}, AppWeb.Hooks.ActiveLink] do
      # live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", AppWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{AppWeb.UserAuth, :ensure_authenticated}, AppWeb.Hooks.ActiveLink] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", AppWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :authenticated,
      on_mount: [{AppWeb.UserAuth, :mount_current_user}, AppWeb.Hooks.ActiveLink] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  scope "/admin", AppWeb do
    pipe_through [:browser, :require_authenticated_user, :ensure_admin]

    live_session :admin,
      on_mount: [
        {AppWeb.UserAuth, :ensure_authenticated},
        {AppWeb.UserAuth, :ensure_admin},
        AppWeb.Hooks.ActiveLink
      ] do
      live "/", AdminLive, :home
      live "/posts", PostsLive, :index
      live "/posts/new", PostsLive, :new
    end

    live_dashboard "/dashboard", metrics: AppWeb.Telemetry
  end
end