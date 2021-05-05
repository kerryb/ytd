defmodule YTD.Activities do
  @moduledoc """
  Context (and server) to handle persistance of activities.
  """

  @behaviour YTD.Activities.API

  use GenServer

  import Ecto.Query

  alias Phoenix.PubSub
  alias YTD.Activities.{Activity, API}
  alias YTD.Repo

  @impl API
  def fetch_activities(pid, user) do
    send(pid, {:existing_activities, get_existing_activities(user)})
    strava_api().stream_activities_since(pid, user, latest_activity_or_beginning_of_year(user))
    :ok
  end

  @impl API
  def refresh_activities(pid, user) do
    strava_api().stream_activities_since(pid, user, latest_activity_or_beginning_of_year(user))
    :ok
  end

  defp latest_activity_or_beginning_of_year(user) do
    case get_latest_activity(user) do
      nil -> Timex.beginning_of_year(DateTime.utc_now())
      activity -> activity.start_date
    end
  end

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
  def handle_info({:reset_activities, user}, state) do
    delete_all_activities(user)
    broadcast_get_new_activities(user, [])
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

  defp get_latest_activity(user) do
    Repo.one(
      from a in Activity, where: a.user_id == ^user.id, order_by: [desc: a.start_date], limit: 1
    )
  end

  defp delete_all_activities(user) do
    Repo.delete_all(from a in Activity, where: a.user_id == ^user.id)
  end

  defp broadcast_get_new_activities(user, [] = _activities) do
    beginning_of_year = Timex.beginning_of_year(DateTime.utc_now())
    PubSub.broadcast!(:ytd, "strava", {:get_new_activities, user, beginning_of_year})
  end

  defp broadcast_activity(activity) do
    PubSub.broadcast!(:ytd, "user:#{activity.user_id}", {:new_activity, activity})
  end

  defp broadcast_all_activities_fetched(user) do
    PubSub.broadcast!(:ytd, "user:#{user.id}", :all_activities_fetched)
  end

  defp strava_api, do: Application.fetch_env!(:ytd, :strava_api)
end
