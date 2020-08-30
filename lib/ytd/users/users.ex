defmodule YTD.Users do
  @moduledoc """
  Entry point functions for Users context, dealing with saved users of the
  application.
  """

  @behaviour YTD.Users.API

  alias Ecto.Multi
  alias YTD.Repo
  alias YTD.Users.{Queries, SaveTokens, User}

  @spec get_user_from_athlete_id(String.t()) :: User.t() | nil
  def get_user_from_athlete_id(athlete_id) do
    athlete_id |> Queries.get_user_from_athlete_id() |> Repo.one()
  end

  @spec save_user_tokens(String.t(), String.t(), String.t()) ::
          {:ok, any()}
          | {:error, any()}
          | {:error, Multi.name(), any(), %{required(Multi.name()) => any()}}
  def save_user_tokens(athlete_id, access_token, refresh_token) do
    Repo.transaction(SaveTokens.call(athlete_id, access_token, refresh_token))
  end
end
