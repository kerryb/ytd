defmodule YTD.Users do
  @moduledoc """
  Entry point functions for Users context, dealing with saved users of the
  application.
  """

  @behaviour YTD.Users.API

  use GenServer

  alias Phoenix.PubSub
  alias YTD.Repo
  alias YTD.Users.{Queries, SaveTokens}

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
    tokens |> SaveTokens.call() |> Repo.transaction()
  end

  @impl GenServer
  def handle_info({:token_refreshed, tokens}, state) do
    save_user_tokens(tokens)
    # Just for the test really
    PubSub.broadcast!(:ytd, "user-updates", {:updated, tokens.athlete_id})
    {:noreply, state}
  end
end
