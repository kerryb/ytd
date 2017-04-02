defmodule Ytd.Mixfile do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      preferred_cli_env: preferred_cli_env(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [plt_add_deps: :transitive],
    ]
  end

  defp deps do
    [
      {:credo, ">= 0.7.0", only: [:dev, :test]},
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
end
