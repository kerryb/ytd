# credo:disable-for-this-file Credo.Check.Readability.Specs
# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule YTD.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: YTD.Supervisor]
    Supervisor.start_link(children(), opts)
  end

  defp children do
    [
      YTD.Repo,
      YTDWeb.Telemetry,
      {Phoenix.PubSub, name: :ytd},
      {SiteEncrypt.Phoenix, YTDWeb.Endpoint}
    ]
  end

  def config_change(changed, _new, removed) do
    YTDWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
