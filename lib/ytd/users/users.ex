defmodule YTD.Users do
  @moduledoc """
  Entry point functions for Users context, dealing with saved users of the
  application.
  """

  @behaviour YTD.Users.API

  use GenServer

  alias Phoenix.PubSub
  alias YTD.Repo
  alias YTD.Users.{Create, Queries, UpdateSelectedActivityType, UpdateSelectedUnit, UpdateTokens}

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_arg) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl GenServer
  def init(_arg) do
    PubSub.subscribe(:ytd, "users")
    {:ok, []}
  end

  @impl YTD.Users.API
  def get_user_from_athlete_id(athlete_id) do
    athlete_id |> Queries.get_user_from_athlete_id() |> Repo.one()
  end

  @impl YTD.Users.API
  def save_user_tokens(tokens) do
    case get_user_from_athlete_id(tokens.athlete_id) do
      nil -> tokens |> Create.call() |> Repo.transaction()
      user -> user |> UpdateTokens.call(tokens) |> Repo.transaction()
    end
  end

  @impl GenServer
  def handle_info({:token_refreshed, user, tokens}, state) do
    user |> UpdateTokens.call(tokens) |> Repo.transaction()
    # Just for the test really
    PubSub.broadcast!(:ytd, "user-updates", {:updated, user})
    {:noreply, state}
  end

  def handle_info({:activity_type_changed, user, type}, state) do
    user |> UpdateSelectedActivityType.call(type) |> Repo.transaction()
    # Just for the test really
    PubSub.broadcast!(:ytd, "user-updates", {:updated, user})
    {:noreply, state}
  end

  def handle_info({:unit_changed, user, type}, state) do
    user |> UpdateSelectedUnit.call(type) |> Repo.transaction()
    # Just for the test really
    PubSub.broadcast!(:ytd, "user-updates", {:updated, user})
    {:noreply, state}
  end
end
