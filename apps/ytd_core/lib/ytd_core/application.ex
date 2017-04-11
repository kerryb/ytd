defmodule YTDCore.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(YTDCore.Athlete, []),
    ]

    opts = [strategy: :one_for_one, name: YTDCore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
