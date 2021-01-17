defmodule YTD.Strava.Activities do
  @moduledoc """
  API wrapper for retrieving an athlete's activities from Strava.
  """

  use GenServer

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_arg) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl GenServer
  def init(_arg) do
    Phoenix.PubSub.subscribe(YTD.PubSub, "strava")
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
        token_refreshed: &publish_token_refreshed(user, &1)
      )

    Strava.Paginator.stream(&Strava.Activities.get_logged_in_athlete_activities(client, &1))
    |> Stream.take_while(&(DateTime.compare(&1.start_date, timestamp) == :gt))
    |> Enum.each(&publish_activity(user, &1))

    publish_all_activities_fetched(user)
  end

  defp publish_token_refreshed(user, client) do
    Phoenix.PubSub.broadcast(
      YTD.PubSub,
      "user:#{user.id}",
      {:token_refreshed, client.token.access_token, client.token.refresh_token}
    )
  end

  defp publish_activity(user, activity) do
    Phoenix.PubSub.broadcast(YTD.PubSub, "user:#{user.id}", {:new_activity, activity})
  end

  defp publish_all_activities_fetched(user) do
    Phoenix.PubSub.broadcast(YTD.PubSub, "user:#{user.id}", {:all_activities_fetched})
  end
end
