defmodule YTD.Activities.API do
  @moduledoc """
  API behaviour for the Activities context.
  """

  alias Strava.SummaryActivity
  alias YTD.Users.User

  @callback fetch_activities(pid :: pid(), user :: User.t()) :: :ok
  @callback refresh_activities(pid :: pid(), user :: User.t()) :: :ok
  @callback reload_activities(pid :: pid(), user :: User.t()) :: :ok
  @callback save_activity(user :: User.t(), activity :: SummaryActivity.t()) :: :ok
end
