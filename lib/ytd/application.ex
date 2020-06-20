# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Ytd.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Ytd.Repo,
      # Start the Telemetry supervisor
      YtdWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Ytd.PubSub},
      # Start the Endpoint (http/https)
      YtdWeb.Endpoint
      # Start a worker by calling: Ytd.Worker.start_link(arg)
      # {Ytd.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ytd.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    YtdWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
