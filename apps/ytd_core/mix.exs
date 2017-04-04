defmodule YTDCore.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ytd_core,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      preferred_cli_env: preferred_cli_env(),
      elixirc_options: [warnings_as_errors: true],
      test_coverage: [tool: ExCoveralls],
    ]
  end

  def application do
    [extra_applications: [:hackney, :httpoison, :logger, :strava]]
  end

  defp deps do
    [
      {:exvcr, ">= 0.8.0", only: :test},
      {:httpoison, ">= 0.10.0"},
      {:mock, ">= 0.2.0", only: :test},
      {:strava, ">= 0.3.0"},
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
end
