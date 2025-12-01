defmodule Site.MixProject do
  use Mix.Project

  def project do
    [
      app: :site,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :dev,
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
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
      {:phoenix, "~> 1.8.2"},
      {:phoenix_live_view, "~> 1.1.18"},
      {:phoenix_ecto, "~> 4.7"},
      {:phoenix_html, "~> 4.3"},
      {:phoenix_live_reload, "~> 1.6", only: :dev},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:bandit, "~> 1.8"},
      {:lazy_html, "~> 0.1"},
      {:ecto_sql, "~> 3.13"},
      {:ecto_sqlite3, ">= 0.0.0"},
      {:bcrypt_elixir, "~> 3.3"},
      {:dns_cluster, "~> 0.2"},
      {:telemetry_metrics, "~> 1.1"},
      {:telemetry_poller, "~> 1.1"},
      {:gettext, "~> 1.0"},
      {:swoosh, "~> 1.19"},
      {:req, "~> 0.5"},

      # Utilities
      {:oban, "~> 2.20"},
      {:nebulex, "~> 2.6"},
      {:decorator, "~> 1.4"},
      {:nimble_publisher, "~> 1.1"},
      {:nimble_csv, "~> 1.3"},
      {:mdex, "~> 0.10"},
      {:recase, "~> 0.9"},
      {:dotenvy, "~> 1.1"},
      {:geocalc, "~> 0.8"},
      {:uniq, "~> 0.6"},
      {:owl, "~> 0.6"},
      # {:litestream, "~> 0.3.0"},
      # {:image, "~> 0.62.1"},

      # Development
      {:igniter, "~> 0.7", only: [:dev]},
      {:credo, "~> 1.7", only: :dev, runtime: false},
      {:tidewave, "~> 0.5", only: [:dev]},
      {:live_debugger, "~> 0.5", only: :dev},
      # {:benchee, "~> 1.4", only: :dev},

      # Assets
      {:bun, "~> 1.5", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:lucide_icons,
       github: "lucide-icons/lucide",
       tag: "0.544.0",
       sparse: "icons",
       app: false,
       compile: false,
       depth: 1},
      {:simple_icons,
       github: "simple-icons/simple-icons",
       tag: "15.16.0",
       sparse: "icons",
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
      "assets.setup": ["bun.install --if-missing", "bun assets install"],
      "assets.build": ["bun js", "bun css"],
      "assets.deploy": ["bun css --minify", "bun js --minify", "phx.digest"],
      "assets.format": "cmd npm run format --prefix assets"
    ]
  end
end
