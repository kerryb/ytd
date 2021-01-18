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
    user |> get_existing_activities() |> publish_existing_activities(user)
    publish_get_new_activities(user)
    {:noreply, state}
  end

  def handle_info({:new_activity, user, summary}, state) do
    activity =
      summary
      |> Activity.from_strava_activity_summary(user)
      |> Repo.insert!()

    publish_activity(activity)
    {:noreply, state}
  end

  def handle_info({:all_activities_fetched, user}, state) do
    publish_all_activities_fetched(user)
    {:noreply, state}
  end

  defp get_existing_activities(user) do
    Repo.all(from a in Activity, where: a.user_id == ^user.id)
  end

  defp publish_existing_activities(activities, user) do
    PubSub.broadcast!(:ytd, "user#{user.id}", {:existing_activities, activities})
  end

  defp publish_get_new_activities(user) do
    PubSub.broadcast!(:ytd, "strava", {:get_new_activities, user})
  end

  defp publish_activity(activity) do
    PubSub.broadcast!(:ytd, "user:#{activity.user_id}", {:new_activity, activity})
  end

  defp publish_all_activities_fetched(user) do
    PubSub.broadcast!(:ytd, "user:#{user.id}", :all_activities_fetched)
  end
end
