defmodule Ytd.Mixfile do
  use Mix.Project

  def project do
    [apps_path: "apps",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  defp deps do
    [
      {:credo, ">= 0.7.0", only: [:dev, :test]},
      {:dialyxir, ">= 0.5.0", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.14.0", only: :dev, runtime: false},
    ]
  end
end
