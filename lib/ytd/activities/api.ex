defmodule YTD.Activities.API do
  @moduledoc """
  API behaviour for the Activities context.
  """

  alias YTD.Users.User

  @callback fetch_activities(pid(), User.t()) :: :ok
  @callback refresh_activities(pid(), User.t()) :: :ok
end
