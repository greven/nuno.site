defmodule App.MixProject do
  use Mix.Project

  def project do
    [
      app: :app,
      version: "0.1.0",
      elixir: "~> 1.17",
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
      {:phoenix, "~> 1.7.18"},
      {:phoenix_live_view, "~> 1.0.2"},
      {:phoenix_ecto, "~> 4.6"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:phoenix_live_dashboard, "~> 0.8"},

      # HTTP server
      {:bandit, "~> 1.5"},

      # HTTP Client
      {:req, "~> 0.5"},

      # Database
      {:ecto_sql, "~> 3.12"},
      {:ecto_sqlite3, "~> 0.18"},
      # {:litestream, "~> 0.3.0"},

      # Mail
      {:swoosh, "~> 1.17"},

      # Crypto,
      {:bcrypt_elixir, "~> 3.2"},

      # i18n
      {:gettext, "~> 0.26"},

      # Telemetry
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.1"},

      # Caching
      {:nebulex, "~> 2.6"},
      {:decorator, "~> 1.4"},

      # Content
      {:mdex, "~> 0.1"},
      {:nimble_publisher, "~> 1.1"},
      {:phoenix_seo, "~> 0.1"},
      {:atomex, "~> 0.5"},

      # Utils
      {:floki, "~> 0.36"},
      {:nimble_csv, "~> 1.2"},
      # TODO: Can we remove timex and create our own relative time function?
      {:timex, "~> 3.7"},
      {:uniq, "~> 0.6"},
      {:earmark, "~> 1.4"},
      {:dotenvy, "~> 1.0"},
      {:image, "~> 0.54"},
      {:geocalc, "~> 0.8"},

      # Assets
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:iconify_ex, "~> 0.6"},

      # Development
      {:kino, "~> 0.11", only: :dev},
      {:credo, "~> 1.7", only: :dev, runtime: false},
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
