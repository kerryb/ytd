# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule YTD.Activities do
  @moduledoc """
  Context (and server) to handle persistance of activities.
  """

  @behaviour YTD.Activities.API

  use Boundary, top_level?: true, deps: [Ecto, YTD.Repo, YTD.Users]

  import Ecto.Query

  alias Phoenix.PubSub
  alias YTD.Activities.Activity
  alias YTD.Activities.API
  alias YTD.Activities.WeekGroup
  alias YTD.Repo
  alias YTD.Users.User

  @impl API
  def get_existing_activities(user) do
    beginning_of_year = Timex.beginning_of_year(DateTime.utc_now())

    Repo.all(
      from(a in Activity,
        where: a.user_id == ^user.id,
        where: a.start_date >= ^beginning_of_year,
        order_by: a.start_date
      )
    )
  end

  @impl API
  def fetch_activities(user) do
    stream_activities_from_strava(user, latest_activity_or_beginning_of_year(user))
    :ok
  end

  @impl API
  def reload_activities(user) do
    delete_all_activities(user)
    stream_activities_from_strava(user, Timex.beginning_of_year(DateTime.utc_now()))
    :ok
  end

  defp stream_activities_from_strava(user, timestamp) do
    strava_api().stream_activities_since(user, timestamp, fn activity ->
      saved_activity = save_activity(user, activity)
      PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", {:new_activity, saved_activity})
    end)

    PubSub.broadcast!(:ytd, "athlete:#{user.athlete_id}", :all_activities_fetched)
  end

  defp latest_activity_or_beginning_of_year(user) do
    case get_latest_activity(user) do
      nil -> Timex.beginning_of_year(DateTime.utc_now())
      activity -> activity.start_date
    end
  end

  defp get_latest_activity(user) do
    Repo.one(from(a in Activity, where: a.user_id == ^user.id, order_by: [desc: a.start_date], limit: 1))
  end

  defp delete_all_activities(user), do: Repo.delete_all(from(a in Activity, where: a.user_id == ^user.id))

  @impl API
  def save_activity(user, activity) do
    activity
    |> Activity.from_strava_activity(user)
    |> Repo.insert!(
      on_conflict: {:replace, [:name, :type, :start_date, :distance, :updated_at]},
      conflict_target: :strava_id
    )
  end

  @impl API
  def by_week_and_day(activities, today \\ Date.utc_today()) do
    activities |> Enum.group_by(&Timex.iso_week(&1.start_date)) |> group_into_weeks(today)
  end

  defp group_into_weeks(activities_by_week, today) do
    {_, current_week} = Timex.iso_week(today)

    Enum.map(
      current_week..1,
      &week_activities(&1, today.year, activities_by_week[{today.year, &1}])
    )
  end

  defp week_activities(week, year, activities) do
    %WeekGroup{
      from: Timex.from_iso_triplet({year, week, 1}),
      to: Timex.from_iso_triplet({year, week, 7}),
      day_activities: day_activities(activities),
      total: total(activities)
    }
  end

  defp total(nil), do: 0
  defp total(activities), do: activities |> Enum.map(& &1.distance) |> Enum.sum()

  @empty_days Map.new(1..7, &{&1, []})
  defp day_activities(nil), do: @empty_days

  @dialyzer {:nowarn_function, day_activities: 1}
  defp day_activities(activities) do
    activities
    |> Enum.sort_by(& &1.start_date, DateTime)
    |> Enum.group_by(&Timex.weekday!(&1.start_date))
    |> then(&Map.merge(@empty_days, &1))
  end

  @impl API
  def activity_created(athlete_id, activity_id) do
    user = Repo.one(from(u in User, where: u.athlete_id == ^athlete_id))

    with {:ok, activity} <- strava_api().get_activity(user, activity_id) do
      saved_activity = save_activity(user, activity)
      PubSub.broadcast!(:ytd, "athlete:#{athlete_id}", {:new_activity, saved_activity})
    end
  end

  @impl API
  def activity_updated(athlete_id, activity_id) do
    user = Repo.one(from(u in User, where: u.athlete_id == ^athlete_id))

    with {:ok, activity} <- strava_api().get_activity(user, activity_id) do
      saved_activity = save_activity(user, activity)
      PubSub.broadcast!(:ytd, "athlete:#{athlete_id}", {:updated_activity, saved_activity})
    end
  end

  @impl API
  def activity_deleted(athlete_id, activity_id) do
    Repo.delete_all(from(a in Activity, where: a.strava_id == ^activity_id))
    PubSub.broadcast!(:ytd, "athlete:#{athlete_id}", {:deleted_activity, activity_id})
  end

  defp strava_api, do: Application.fetch_env!(:ytd, :strava_api)
end
