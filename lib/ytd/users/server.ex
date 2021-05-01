defmodule YTD.Users.Server do
  @moduledoc """
  Server for asynchronous user operations.
  """

  use GenServer

  alias Phoenix.PubSub
  alias YTD.Repo
  alias YTD.Users.UpdateName

  require Logger

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_arg) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl GenServer
  def init(_arg) do
    PubSub.subscribe(:ytd, "users")
    {:ok, []}
  end

  @impl GenServer
  def handle_info({:update_name, user}, state) do
    broadcast_get_athlete_details(user)
    {:noreply, state}
  end

  def handle_info({:athlete, user, athlete}, state) do
    name = "#{athlete.firstname} #{athlete.lastname}"

    unless user.name == name do
      {:ok, %{update_name: updated_user}} = user |> UpdateName.call(name) |> Repo.transaction()
      PubSub.broadcast!(:ytd, "user:#{user.id}", {:name_updated, updated_user})
    end

    {:noreply, state}
  end

  def handle_info(message, state) do
    Logger.warn("#{__MODULE__} Received unexpected message #{inspect(message)}")
    {:noreply, state}
  end

  defp broadcast_get_athlete_details(user) do
    PubSub.broadcast!(:ytd, "strava", {:get_athlete_details, user})
  end
end
