defmodule YTD.Users do
  @moduledoc """
  Entry point functions for Users context, dealing with saved users of the
  application.
  """

  @behaviour YTD.Users.API

  alias YTD.Repo

  alias YTD.Users.{
    API,
    Create,
    Queries,
    UpdateSelectedActivityType,
    UpdateSelectedUnit,
    UpdateTokens
  }

  @impl API
  def get_user_from_athlete_id(athlete_id) do
    athlete_id |> Queries.get_user_from_athlete_id() |> Repo.one()
  end

  @impl API
  def save_user_tokens(tokens) do
    case get_user_from_athlete_id(tokens.athlete_id) do
      nil -> tokens |> Create.call() |> Repo.transaction()
      user -> user |> UpdateTokens.call(tokens) |> Repo.transaction()
    end
  end

  @impl API
  def save_activity_type(user, type) do
    user |> UpdateSelectedActivityType.call(type) |> Repo.transaction()
  end

  @impl API
  def save_unit(user, unit) do
    user |> UpdateSelectedUnit.call(unit) |> Repo.transaction()
  end
end
