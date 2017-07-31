defmodule YTDWeb.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ytd_web,
      version: version(),
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.2",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  defp version, do: "../../VERSION" |> File.read! |> String.trim

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {YTDWeb, []},
     applications: [
       :phoenix,
       :phoenix_pubsub,
       :phoenix_html,
       :phoenix_slime,
       :plug,
       :cowboy,
       :logger,
       :gettext,
       :ytd_core,
     ]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:cowboy, ">= 1.0.0"},
      {:gettext, ">= 0.11.0"},
      {:mock, ">= 0.2.0", only: :test},
      {:phoenix, ">= 1.3.0"},
      {:phoenix_html, ">= 2.6.0"},
      {:phoenix_integration, ">= 0.2.0", only: :test},
      {:phoenix_live_reload, ">= 1.0.0", only: :dev},
      {:phoenix_pubsub, ">= 1.0.0"},
      {:phoenix_slime, ">= 0.8.0"},
      {:poison, ">= 3.0.0", override: true}, # strava conflicts with phoenix
      {:sobelow, ">= 0.3.0", only: :dev},
      {:ytd_core, in_umbrella: true},
    ]
  end
end
