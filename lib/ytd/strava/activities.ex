defmodule YTD.Strava.Activities do
  @moduledoc """
  Server and API wrapper for retrieving an athlete's activities from Strava.
  """

  use GenServer

  alias Phoenix.PubSub

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_arg) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl GenServer
  def init(_arg) do
    PubSub.subscribe(:ytd, "strava")
    {:ok, []}
  end

  @impl GenServer
  def handle_info({:get_new_activities, user, timestamp}, state) do
    Task.start(fn -> get_new_activities(user, timestamp) end)
    {:noreply, state}
  end

  defp get_new_activities(user, timestamp) do
    client =
      Strava.Client.new(user.access_token,
        refresh_token: user.refresh_token,
        token_refreshed: &broadcast_token_refreshed(user, &1)
      )

    Strava.Paginator.stream(&Strava.Activities.get_logged_in_athlete_activities(client, &1))
    |> Stream.take_while(&(DateTime.compare(&1.start_date, timestamp) == :gt))
    |> Enum.each(&broadcast_activity(user, &1))

    broadcast_all_activities_fetched(user)
  end

  defp broadcast_token_refreshed(user, client) do
    PubSub.broadcast!(:ytd, "users", {:token_refreshed, user, client.token})
  end

  defp broadcast_activity(user, activity) do
    PubSub.broadcast!(:ytd, "activities", {:new_activity, user, activity})
  end

  defp broadcast_all_activities_fetched(user) do
    PubSub.broadcast!(:ytd, "activities", {:all_activities_fetched, user})
  end
end
