# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule YTD.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: YTD.Supervisor]
    Supervisor.start_link(children(Application.fetch_env!(:ytd, :env)), opts)
  end

  defp children(:test) do
    default_children()
  end

  defp children(_env) do
    default_children() ++ [YTD.Activities, YTD.Strava.Activities]
  end

  defp default_children do
    [
      YTD.Repo,
      YTDWeb.Telemetry,
      {Phoenix.PubSub, name: :ytd},
      YTDWeb.Endpoint
    ]
  end

  def config_change(changed, _new, removed) do
    YTDWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
