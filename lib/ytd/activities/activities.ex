# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule YTD.Activities do
  @moduledoc """
  Context (and server) to handle persistance of activities.
  """

  @behaviour YTD.Activities.API

  use Boundary, top_level?: true, deps: [Ecto, YTD.Repo, YTD.Users]

  import Ecto.Query

  alias Phoenix.PubSub
  alias YTD.Activities.{Activity, API}
  alias YTD.Repo
  alias YTD.Users.User

  @impl API
  def get_existing_activities(user) do
    beginning_of_year = Timex.beginning_of_year(DateTime.utc_now())

    Repo.all(
      from a in Activity,
        where: a.user_id == ^user.id,
        where: a.start_date >= ^beginning_of_year
    )
  end

  @impl API
  def fetch_activities(user) do
    stream_activities_from_strava(user, latest_activity_or_beginning_of_year(user))
    :ok
  end

  @impl API
  def refresh_activities(user) do
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
    Repo.one(
      from a in Activity, where: a.user_id == ^user.id, order_by: [desc: a.start_date], limit: 1
    )
  end

  defp delete_all_activities(user) do
    Repo.delete_all(from a in Activity, where: a.user_id == ^user.id)
  end

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
  def activity_created(athlete_id, activity_id) do
    with user <- Repo.one(from u in User, where: u.athlete_id == ^athlete_id),
         {:ok, activity} <- strava_api().get_activity(user, activity_id) do
      saved_activity = save_activity(user, activity)
      PubSub.broadcast!(:ytd, "athlete:#{athlete_id}", {:new_activity, saved_activity})
    end
  end

  @impl API
  def activity_updated(athlete_id, activity_id) do
    with user <- Repo.one(from u in User, where: u.athlete_id == ^athlete_id),
         {:ok, activity} <- strava_api().get_activity(user, activity_id) do
      saved_activity = save_activity(user, activity)
      PubSub.broadcast!(:ytd, "athlete:#{athlete_id}", {:updated_activity, saved_activity})
    end
  end

  @impl API
  def activity_deleted(athlete_id, activity_id) do
    Repo.delete_all(from a in Activity, where: a.strava_id == ^activity_id)
    PubSub.broadcast!(:ytd, "athlete:#{athlete_id}", {:deleted_activity, activity_id})
  end

  defp strava_api, do: Application.fetch_env!(:ytd, :strava_api)
end
