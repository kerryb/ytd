defmodule YTD.MixProject do
  use Mix.Project

  def project do
    [
      app: :ytd,
      version: version(),
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:boundary] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: dialyzer(),
      preferred_cli_env: preferred_cli_env(),
      releases: releases(),
      boundary: boundary()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {YTD.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
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
      {:assertions, "~> 0.10", only: :test},
      {:boundary, "~> 0.8", runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test]},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ecto_psql_extras, "~> 0.6"},
      {:ecto_sql, "~> 3.4"},
      {:esbuild, "~> 0.2", runtime: Mix.env() == :dev},
      {:ex_doc, "~> 0.21", only: :dev},
      {:ex_machina, "~> 2.4", only: :test},
      {:excoveralls, "~> 0.13", only: :test},
      {:faker, "~> 0.17", only: :test},
      {:floki, ">= 0.0.0", only: :test},
      {:gettext, "~> 0.11"},
      {:hammox, "~> 0.2", only: :test},
      {:jason, "~> 1.0"},
      {:phoenix, "~> 1.7.0-rc.2", override: true},
      {:phoenix_ecto, "~> 4.1"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_dashboard, "~> 0.5"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "0.18.11"},
      {:phoenix_view, "~> 2.0"},
      {:plug_cowboy, "~> 2.0"},
      {:postgrex, ">= 0.0.0"},
      {:strava, "~> 1.0"},
      {:tailwind, "~> 0.1", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:timex, "~> 3.6"}
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
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.migrate": ["ecto.migrate", "ecto.dump"],
      "ecto.rollback": ["ecto.rollback", "ecto.dump"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": ["tailwind default --minify", "phx.digest"]
    ]
  end

  defp dialyzer, do: [plt_add_deps: :app_tree]

  defp preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.html": :test
    ]
  end

  defp version, do: "VERSION" |> File.read() |> extract_version()

  # A small hack so we can run `mix deps.get` etc in the release process
  # without the docker cache being invalidated just because `VERSION` has
  # changed
  defp extract_version({:ok, version}), do: String.trim(version)
  defp extract_version(_), do: "0.0.0"

  defp releases do
    [
      ytd: [
        include_executables_for: [:unix],
        steps: [:assemble, :tar]
      ]
    ]
  end

  def boundary() do
    [
      default: [
        check: [
          apps: [:phoenix, :ecto, :strava, {:mix, :runtime}]
        ]
      ]
    ]
  end
end
