defmodule Site.MixProject do
  use Mix.Project

  def project do
    [
      app: :site,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Site.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon, :xmerl]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # Phoenix Framework
      {:phoenix, "~> 1.7.19"},
      {:phoenix_live_view, "~> 1.0.2"},
      {:phoenix_ecto, "~> 4.6"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.8"},

      # HTTP server
      {:bandit, "~> 1.5"},

      # Database
      {:ecto_sql, "~> 3.12"},
      {:ecto_sqlite3, ">= 0.0.0"},
      # {:litestream, "~> 0.3.0"},

      # i18n
      {:gettext, "~> 0.26"},

      # Mail
      {:swoosh, "~> 1.17"},

      # Telemetry
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.1"},

      # Caching
      {:nebulex, "~> 2.6"},
      {:decorator, "~> 1.4"},

      # Utils
      {:uniq, "~> 0.6"},
      {:nimble_csv, "~> 1.2"},
      {:earmark, "~> 1.4"},
      {:dotenvy, "~> 1.0"},
      {:image, "~> 0.56"},
      # {:geocalc, "~> 0.8"},
      {:dns_cluster, "~> 0.1.3"},
      {:floki, ">= 0.30.0", only: :test},

      # Assets
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      # {:iconify_ex, "~> 0.6"},

      # Content
      {:mdex, "~> 0.3"},
      {:nimble_publisher, "~> 1.1"},
      {:phoenix_seo, "~> 0.1"},
      {:atomex, "~> 0.5"},

      # Development
      {:credo, "~> 1.7", only: :dev, runtime: false},

      # TODO: --> TO REMOVE
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind site", "esbuild site"],
      "assets.deploy": [
        "tailwind site --minify",
        "esbuild site --minify",
        "phx.digest"
      ]
    ]
  end
end
