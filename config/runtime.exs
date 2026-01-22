import Config
import Dotenvy

source!([".env", System.get_env()])

# For env variables the reason we are using default values is to
# allow certain environment (like GitHub Actions) to run without having
# to set all the variables that aren't needed for that specific task.

if System.get_env("PHX_SERVER") do
  config :site, SiteWeb.Endpoint, server: true
end

config :site, :steam,
  steam_id: env!("STEAM_ID", :string!, "steam-id"),
  api_key: env!("STEAM_API_KEY", :string!, "steam-api-key")

config :site, :bluesky,
  handle: env!("BLUESKY_HANDLE", :string!, "bluesky-handle"),
  app_password: env!("BLUESKY_APP_PASSWORD", :string!, "bluesky-app-password")

config :site, :lastfm,
  api_key: env!("LASTFM_API_KEY", :string!, "lastfm-api-key"),
  shared_secret: env!("LASTFM_SHARED_SECRET", :string!, "lastfm-shared-secret"),
  username: env!("LASTFM_USERNAME", :string!, "lastfm-username"),
  session_key: env!("LASTFM_SESSION_KEY", :string!, "lastfm-session-key")

config :site, :spotify,
  client_id: env!("SPOTIFY_CLIENT_ID", :string!, "spotify-client-id"),
  client_secret: env!("SPOTIFY_CLIENT_SECRET", :string!, "spotify-client-secret"),
  refresh_token: env!("SPOTIFY_REFRESH_TOKEN", :string!, "spotify-refresh-token")

config :site, :github, access_token: env!("GITHUB_ACCESS_TOKEN", :string!, "github-access-token")

config :site, :cdn,
  base_url: env!("CDN_BASE_URL", :string!, "https://cdn.nuno.site"),
  access_key_id: env!("R2_ACCESS_KEY_ID", :string, "access-key-id"),
  secret_access_key: env!("R2_SECRET_ACCESS_KEY", :string, "secret-key"),
  endpoint_url: env!("R2_ENDPOINT_URL", :string!, "public-endpoint-url"),
  bucket: env!("R2_BUCKET_NAME", :string!, "bucket-name")

# ------------------------------------------
#  Production environment
# ------------------------------------------

if config_env() == :prod do
  database_path =
    System.get_env("DATABASE_PATH") ||
      raise """
      environment variable DATABASE_PATH is missing.
      For example: /etc/site/site.db
      """

  config :site, Site.Repo,
    database: database_path,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "nuno.site"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :site, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :site, SiteWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base
end
