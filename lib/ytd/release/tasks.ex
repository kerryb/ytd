defmodule YTD.Release.Tasks do
  @moduledoc """
  Database migration task for deployment (mix is not available in production).
  Called from distillery hook.

  Based on [this article](http://blog.firstiwaslike.com/elixir-deployments-with-distillery-running-ecto-migrations/)
  """

  alias YTD.Database

  def migrate do
    {:ok, _} = Application.ensure_all_started(:ytd)
    Database.migrate()
  end
end
