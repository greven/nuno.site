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
      deps: deps(),
      listeners: [Phoenix.CodeReloader]
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
      {:phoenix, "~> 1.8.0-rc.3", override: true},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_ecto, "~> 4.6"},
      {:phoenix_html, "~> 4.2"},
      {:phoenix_live_reload, "~> 1.6", only: :dev},
      {:phoenix_live_dashboard, "~> 0.8"},

      # HTTP server
      {:bandit, "~> 1.6"},

      # Database
      {:ecto_sql, "~> 3.12"},
      {:ecto_sqlite3, ">= 0.0.0"},
      # {:litestream, "~> 0.3.0"},

      # Mail
      {:swoosh, "~> 1.19"},

      # Telemetry
      {:telemetry_metrics, "~> 1.1"},
      {:telemetry_poller, "~> 1.1"},

      # i18n
      {:gettext, "~> 0.26"},

      # Caching
      {:nebulex, "~> 2.6"},
      {:decorator, "~> 1.4"},

      # Utils
      {:req, "~> 0.5"},
      {:dns_cluster, "~> 0.2"},
      {:lazy_html, "~> 0.1.0"},
      {:nimble_csv, "~> 1.2"},
      {:recase, "~> 0.8"},
      {:dotenvy, "~> 1.1"},
      {:geocalc, "~> 0.8"},
      # {:uniq, "~> 0.6"},
      # {:earmark, "~> 1.4"},
      # {:image, "~> 0.56"},

      # Content
      {:mdex, "~> 0.6"},
      {:nimble_publisher, "~> 1.1"},
      # {:phoenix_seo, "~> 0.1"},
      # {:atomex, "~> 0.5"},

      # Assets
      {:esbuild, "~> 0.9", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.5",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {
        :lucide_icons,
        github: "lucide-icons/lucide",
        tag: "0.487.0",
        sparse: "icons",
        app: false,
        compile: false,
        depth: 1
      },
      {:simple_icons,
       github: "simple-icons/simple-icons",
       tag: "14.12.1",
       sparse: "icons",
       app: false,
       compile: false,
       depth: 1},

      # Development
      {:credo, "~> 1.7", only: :dev, runtime: false},
      {:live_debugger, "~> 0.2.2", only: :dev},
      {:benchee, "~> 1.4", only: :dev}
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
      ],
      "vendor.update": [
        "cmd cd ./assets/vendor && curl -sLO https://raw.githubusercontent.com/buunguyen/topbar/refs/heads/master/topbar.js"
      ]
    ]
  end
end
