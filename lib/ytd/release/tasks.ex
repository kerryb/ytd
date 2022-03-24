defmodule YTD.Release.Tasks do
  @moduledoc """
  Simple database migration task for deployment (mix is not available in production).
  """

  use Boundary, top_level?: true, deps: []

  alias Ecto.{Migrator, Repo}

  @app :ytd

  @spec migrate :: [{:ok, any(), any()}] | no_return()
  def migrate do
    for repo <- repos() do
      {:ok, _return, _apps} = Migrator.with_repo(repo, &Migrator.run(&1, :up, all: true))
    end
  end

  @spec rollback(Repo.t(), integer()) :: {:ok, any(), any()} | no_return()
  def rollback(repo, version) do
    {:ok, _return, _apps} = Migrator.with_repo(repo, &Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end
end
