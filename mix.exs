defmodule App.MixProject do
  use Mix.Project

  def project do
    [
      app: :app,
      version: "0.1.0",
      elixir: "~> 1.16",
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
      mod: {App.Application, []},
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
      {:phoenix, "~> 1.7.12"},
      {:phoenix_live_view, "~> 1.0.0-rc.0", override: true},
      {:phoenix_ecto, "~> 4.6"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:phoenix_live_dashboard, "~> 0.8"},

      # HTTP server
      {:bandit, "~> 1.5"},

      # HTTP Client
      {:req, "~> 0.4"},

      # Database
      {:ecto_sql, "~> 3.11"},
      {:ecto_sqlite3, "~> 0.15"},
      # {:litestream, "~> 0.3.0"},

      # Mail
      {:swoosh, "~> 1.16"},

      # Crypto,
      {:bcrypt_elixir, "~> 3.1"},

      # JSON & CSV
      {:jason, "~> 1.4"},

      # i18n
      {:gettext, "~> 0.24"},

      # Telemetry
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.1"},

      # Caching
      {:nebulex, "~> 2.5"},
      {:decorator, "~> 1.4"},

      # Content
      # {:makeup_elixir, ">= 0.0.0"},

      # Utils
      # TODO: Drop :timex for standard lib?
      {:floki, "~> 0.36"},
      {:timex, "~> 3.7"},
      {:earmark, "~> 1.4"},
      {:slugify, "~> 1.3"},
      {:dotenvy, "~> 0.8"},
      {:image, "~> 0.47"},

      # Assets
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},

      # Development
      {:credo, "~> 1.7", only: [:dev], runtime: false},
      {:sobelow, "~> 0.13", only: :dev}
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
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": [
        "tailwind default --minify",
        "esbuild default --minify",
        "phx.digest"
      ],
      translate: ["gettext.extract", "gettext.merge priv/gettext"]
    ]
  end
end
