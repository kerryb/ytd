defmodule YTD.Activities.API do
  @moduledoc """
  API behaviour for the Activities context.
  """

  alias Strava.SummaryActivity
  alias YTD.Users.User

  @callback fetch_activities(User.t()) :: :ok
  @callback refresh_activities(User.t()) :: :ok
  @callback reload_activities(User.t()) :: :ok
  @callback save_activity(user :: User.t(), activity :: SummaryActivity.t()) :: :ok
end
