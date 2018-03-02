defmodule YTD.Release.Tasks do
  @moduledoc """
  Simple database migration task for deployment (mix is not available in production).
  Called from distillery hook.
  """

  alias Ecto.Migrator
  alias YTD.Repo

  def migrate do
    {:ok, _} = Application.ensure_all_started(:ytd)
    path = Application.app_dir(:ytd, "priv/repo/migrations")
    Migrator.run(Repo, path, :up, all: true)
  end
end
