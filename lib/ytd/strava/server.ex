# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule YTD.Strava.Server do
  @moduledoc """
  Server for asynchronously retrieving data from Strava.
  """

  use GenServer

  alias Phoenix.PubSub
  alias YTD.Users

  require Logger

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

  def handle_info({:get_athlete_details, user}, state) do
    Task.start(fn -> get_athlete_details(user) end)
    {:noreply, state}
  end

  def handle_info(message, state) do
    Logger.warn("#{__MODULE__} Received unexpected message #{inspect(message)}")
    {:noreply, state}
  end

  defp get_new_activities(user, timestamp) do
    client = client(user)

    Strava.Paginator.stream(&Strava.Activities.get_logged_in_athlete_activities(client, &1))
    |> Stream.take_while(&(DateTime.compare(&1.start_date, timestamp) == :gt))
    |> Enum.each(&broadcast_activity(user, &1))

    broadcast_all_activities_fetched(user)
  end

  defp get_athlete_details(user) do
    client = client(user)
    {:ok, athlete} = Strava.Athletes.get_logged_in_athlete(client)
    broadcast_athlete(user, athlete)
  end

  defp client(user) do
    Strava.Client.new(user.access_token,
      refresh_token: user.refresh_token,
      token_refreshed: &Users.update_user_tokens(user, &1)
    )
  end

  defp broadcast_activity(user, activity) do
    PubSub.broadcast!(:ytd, "activities", {:new_activity, user, activity})
  end

  defp broadcast_all_activities_fetched(user) do
    PubSub.broadcast!(:ytd, "activities", {:all_activities_fetched, user})
  end

  defp broadcast_athlete(user, athlete) do
    PubSub.broadcast!(:ytd, "users", {:athlete, user, athlete})
  end
end
