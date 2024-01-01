defmodule YTD.Activities.API do
  @moduledoc """
  API behaviour for the Activities context.
  """

  alias Strava.SummaryActivity
  alias YTD.Activities.Activity
  alias YTD.Activities.WeekGroup
  alias YTD.Users.User

  @callback get_existing_activities(User.t()) :: [Activity.t()]
  @callback fetch_activities(User.t()) :: :ok
  @callback reload_activities(User.t()) :: :ok
  @callback save_activity(user :: User.t(), activity :: SummaryActivity.t()) :: :ok
  @callback by_week_and_day(activities :: [Activity.t()]) :: [WeekGroup.t()]
  @callback by_week_and_day(activities :: [Activity.t()], today :: Date.t()) :: [WeekGroup.t()]
  @callback activity_created(athlete_id :: integer(), activity_id :: integer()) :: :ok
  @callback activity_updated(athlete_id :: integer(), activity_id :: integer()) :: :ok
  @callback activity_deleted(athlete_id :: integer(), activity_id :: integer()) :: :ok
end
