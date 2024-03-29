defmodule App.MixProject do
  use Mix.Project

  def project do
    [
      app: :app,
      version: "0.1.0",
      elixir: "~> 1.14",
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
      {:phoenix, "~> 1.7.6"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_view, "~> 0.19.3"},
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:phoenix_live_dashboard, "~> 0.8"},

      # HTTP server
      {:bandit, "~> 0.7"},

      # HTTP Client
      {:finch, "~> 0.16"},

      # Database
      {:ecto_sql, "~> 3.10"},
      {:ecto_sqlite3, "~> 0.10"},
      # {:litestream, "~> 0.3.0"},

      # Mail
      {:swoosh, "~> 1.9"},

      # Crypto,
      {:bcrypt_elixir, "~> 3.0"},

      # Content
      # {:makeup_elixir, ">= 0.0.0"},

      # JSON & CSV
      {:jason, "~> 1.4"},

      # i18n
      {:gettext, "~> 0.22"},

      # Telemetry
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},

      # Caching
      {:nebulex, "~> 2.5"},
      {:decorator, "~> 1.4"},

      # Utils
      {:timex, "~> 3.7"},
      {:earmark, "~> 1.4"},
      {:dotenvy, "~> 0.7"},
      {:slugify, "~> 1.3"},
      {:floki, "~> 0.34"},

      # Assets
      {:esbuild, "~> 0.7.0", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},

      # Development
      {:credo, "~> 1.6", only: [:dev], runtime: false},
      {:sobelow, "~> 0.12", only: :dev}
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
