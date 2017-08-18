defmodule YTDCore.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ytd_core,
      version: version(),
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      preferred_cli_env: preferred_cli_env(),
      elixirc_options: elixirc_options(),
      test_coverage: [tool: ExCoveralls],
    ]
  end

  defp version, do: "../../VERSION" |> File.read! |> String.trim

  def application do
    [
      mod: {YTDCore.Application, []},
      extra_applications: [:hackney, :httpoison, :logger, :strava, :timex],
    ]
  end

  defp deps do
    [
      {:amnesia, "~> 0.2.7"},
      {:exvcr, ">= 0.8.0", runtime: false, only: [:test]},
      {:hackney, "~> 1.8.6"},
      {:httpoison, ">= 0.10.0"},
      {:mock, ">= 0.2.0", only: [:test]},
      {:strava, ">= 0.3.0"},
      {:timex, ">= 0.19.0"},
    ]
  end

  defp preferred_cli_env do
    [
      vcr: :test,
      "vcr.delete": :test,
      "vcr.check": :test,
      "vcr.show": :test,
    ]
  end

  defp elixirc_options do
    if Mix.env == :test, do: [], else: [warnings_as_errors: true]
  end
end
