defmodule YTD.Activities do
  @moduledoc """
  Context (and server) to handle persistance of activities.
  """

  @behaviour YTD.Activities.API

  use Boundary, top_level?: true, deps: [Ecto, YTD.Repo]

  import Ecto.Query

  alias YTD.Activities.{Activity, API}
  alias YTD.Repo

  @impl API
  def fetch_activities(pid, user) do
    send(pid, {:existing_activities, get_existing_activities(user)})
    stream_activities_from_strava(pid, user, latest_activity_or_beginning_of_year(user))
    :ok
  end

  @impl API
  def refresh_activities(pid, user) do
    stream_activities_from_strava(pid, user, latest_activity_or_beginning_of_year(user))
    :ok
  end

  @impl API
  def reload_activities(pid, user) do
    delete_all_activities(user)
    stream_activities_from_strava(pid, user, Timex.beginning_of_year(DateTime.utc_now()))
    :ok
  end

  defp stream_activities_from_strava(pid, user, timestamp) do
    strava_api().stream_activities_since(user, timestamp, fn activity ->
      saved_activity = save_activity(user, activity)
      send(pid, {:new_activity, saved_activity})
    end)

    send(pid, :all_activities_fetched)
  end

  defp latest_activity_or_beginning_of_year(user) do
    case get_latest_activity(user) do
      nil -> Timex.beginning_of_year(DateTime.utc_now())
      activity -> activity.start_date
    end
  end

  defp get_existing_activities(user) do
    Repo.all(from a in Activity, where: a.user_id == ^user.id)
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
    |> Activity.from_strava_activity_summary(user)
    |> Repo.insert!()
  end

  defp strava_api, do: Application.fetch_env!(:ytd, :strava_api)
end
