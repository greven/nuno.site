# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :site, :scopes,
  user: [
    default: true,
    module: Site.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :binary_id,
    schema_table: :users,
    test_data_fixture: Site.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :site,
  ecto_repos: [Site.Repo],
  generators: [binary_id: true, timestamp_type: :utc_datetime]

# Configures the endpoint
config :site, SiteWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: SiteWeb.ErrorHTML, json: SiteWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Site.PubSub,
  live_view: [signing_salt: "yb7vRhBT"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :site, Site.Mailer, adapter: Swoosh.Adapters.Local

config :bun,
  version: "1.3.9",
  assets: [args: [], cd: Path.expand("../assets", __DIR__)],
  js: [
    args:
      ~w(build js/app.js js/workers/color.worker.js --outdir=../priv/static/assets/js --splitting --external /fonts/* --external /images/*),
    cd: Path.expand("../assets", __DIR__)
  ],
  css: [
    args: ~w(run tailwindcss --input=css/app.css --output=../priv/static/assets/css/app.css),
    cd: Path.expand("../assets", __DIR__)
  ]

# Bun needs to specify where colocated JS files should be placed
config :phoenix_live_view, :colocated_js,
  target_directory: Path.expand("../assets/node_modules/phoenix-colocated", __DIR__)

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, JSON

config :site, Oban,
  repo: Site.Repo,
  engine: Oban.Engines.Lite,
  queues: [default: 10, scheduled: 10],
  plugins: [
    Oban.Plugins.Pruner,
    {Oban.Plugins.Cron,
     crontab: [
       {"@reboot", Site.Workers.BlueskySyncWorker},
       {"@hourly", Site.Workers.BlueskySyncWorker}
     ]}
  ]

# Application configuration
config :site, Site.Cache,
  max_size: 1_000_000,
  # Max size of 1 GB
  allocated_memory: 1_000_000_000,
  gc_interval: :timer.hours(48)

config :site, :site_url, "https://nuno.site"
config :site, :cdn_url, "https://cdn.nuno.site"

config :site, :seo,
  default_title: "Nuno Moço - Software Engineer",
  default_description: "Personal website of Nuno Moço, a Software Engineer from Lisbon.",
  default_keywords: "web development, elixir, phoenix, css, javascript, software, programming",
  title_suffix: " · Nuno's Site"

# OG Image Generation
config :ogi, cache: true

# ErrorTracker configuration
config :error_tracker, repo: Site.Repo, otp_app: :site, enabled: true

# Inject the environment into the config
config :site, :env, config_env()

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
