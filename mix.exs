defmodule YTDWeb.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ytd,
      version: version(),
      build_path: "_build",
      config_path: "config/config.exs",
      deps_path: "deps",
      lockfile: "mix.lock",
      elixir: "~> 1.2",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: preferred_cli_env(),
      elixirc_options: elixirc_options(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: dialyzer(),
      deps: deps()
    ]
  end

  defp version, do: "VERSION" |> File.read!() |> String.trim()

  # Configuration for the OTP application.
  #
  #  `mix help compile.app` for more information.
  def application do
    [
      mod: {YTDWeb.Application, []},
      extra_applications: [
        :cowboy,
        :gettext,
        :hackney,
        :httpoison,
        :logger,
        :phoenix,
        :phoenix_html,
        :phoenix_pubsub,
        :phoenix_slime,
        :plug,
        :postgrex,
        :strava,
        :timex
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  #  `mix help deps` for examples and options.
  defp deps do
    [
      {:cowboy, ">= 1.0.0"},
      {:credo, ">= 0.7.0", only: [:dev, :test]},
      {:dialyxir, ">= 0.5.0", only: [:dev], runtime: false},
      {:distillery, "~> 1.3"},
      {:ex_doc, ">= 0.14.0", only: :dev, runtime: false},
      {:excoveralls, ">= 0.6.0", only: :test},
      {:exvcr, ">= 0.8.0", runtime: false, only: [:test]},
      {:gettext, ">= 0.11.0"},
      {:hackney, "~> 1.8.6"},
      {:httpoison, ">= 0.10.0"},
      {:mock, ">= 0.2.0", only: :test},
      {:phoenix, "~> 1.3.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:phoenix_html, ">= 2.6.0"},
      {:phoenix_integration, ">= 0.2.0", only: :test},
      {:phoenix_live_reload, ">= 1.0.0", only: :dev},
      {:phoenix_pubsub, ">= 1.0.0"},
      {:phoenix_slime, ">= 0.8.0"},
      {:plug, "~> 1.8"},
      {:plug_cowboy, "~> 1.0"},
      #  strava conflicts with phoenix
      {:poison, ">= 3.0.0", override: true},
      {:postgrex, ">= 0.0.0"},
      {:sobelow, ">= 0.3.0", only: :dev},
      {:strava, "~> 1.0"},
      {:timex, ">= 0.19.0"}
    ]
  end

  defp preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.html": :test,
      vcr: :test,
      "vcr.delete": :test,
      "vcr.check": :test,
      "vcr.show": :test
    ]
  end

  defp dialyzer do
    [
      plt_add_deps: :transitive,
      ignore_warnings: "config/dialyzer.ignore-warnings"
    ]
  end

  defp elixirc_options do
    if Mix.env() == :test, do: [], else: [warnings_as_errors: true]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.migrate": ["ecto.migrate", "ecto.dump"],
      "ecto.rollback": ["ecto.rollback", "ecto.dump"],
      "test.prepare": ["ecto.create --quiet", "ecto.migrate"]
    ]
  end
end
