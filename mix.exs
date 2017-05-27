defmodule YTD.Mixfile do
  use Mix.Project

  def project do
    [
      version: version(),
      apps_path: "apps",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      preferred_cli_env: preferred_cli_env(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: dialyzer(),
    ]
  end

  defp version, do: "VERSION" |> File.read! |> String.trim

  defp deps do
    [
      {:credo, ">= 0.7.0", only: [:dev, :test]},
      {:distillery, ">= 1.3.2"},
      {:dialyxir, ">= 0.5.0", only: [:dev], runtime: false},
      {:excoveralls, ">= 0.6.0", only: :test},
      {:ex_doc, ">= 0.14.0", only: :dev, runtime: false},
    ]
  end

  defp preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.html": :test,
    ]
  end

  defp dialyzer do
    [
      plt_add_deps: :project,
      ignore_warnings: "config/dialyzer.ignore-warnings",
    ]
  end
end
