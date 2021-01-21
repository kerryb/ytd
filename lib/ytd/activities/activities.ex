defmodule YTD.Activities do
  @moduledoc """
  Server to handle persistance of activities.
  """

  use GenServer

  import Ecto.Query

  alias Phoenix.PubSub
  alias YTD.Activities.Activity
  alias YTD.Repo

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_arg) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl GenServer
  def init(_arg) do
    PubSub.subscribe(:ytd, "activities")
    {:ok, []}
  end

  @impl GenServer
  def handle_info({:get_activities, user}, state) do
    activities = get_existing_activities(user)
    broadcast_existing_activities(activities, user)
    broadcast_get_new_activities(activities, user)
    {:noreply, state}
  end

  def handle_info({:new_activity, user, summary}, state) do
    activity =
      summary
      |> Activity.from_strava_activity_summary(user)
      |> Repo.insert!()

    broadcast_activity(activity)
    {:noreply, state}
  end

  def handle_info({:all_activities_fetched, user}, state) do
    broadcast_all_activities_fetched(user)
    {:noreply, state}
  end

  defp get_existing_activities(user) do
    Repo.all(from a in Activity, where: a.user_id == ^user.id)
  end

  defp broadcast_existing_activities(activities, user) do
    PubSub.broadcast!(:ytd, "user:#{user.id}", {:existing_activities, activities})
  end

  defp broadcast_get_new_activities([] = _activities, user) do
    {:ok, beginning_of_year, _offset} =
      DateTime.from_iso8601("#{Date.utc_today().year}-01-01T00:00:00Z")

    PubSub.broadcast!(:ytd, "strava", {:get_new_activities, user, beginning_of_year})
  end

  defp broadcast_get_new_activities(activities, user) do
    latest = Enum.max_by(activities, & &1.start_date, DateTime)
    PubSub.broadcast!(:ytd, "strava", {:get_new_activities, user, latest.start_date})
  end

  defp broadcast_activity(activity) do
    PubSub.broadcast!(:ytd, "user:#{activity.user_id}", {:new_activity, activity})
  end

  defp broadcast_all_activities_fetched(user) do
    PubSub.broadcast!(:ytd, "user:#{user.id}", :all_activities_fetched)
  end
end
