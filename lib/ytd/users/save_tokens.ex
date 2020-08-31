defmodule YTD.Users.SaveTokens do
  @moduledoc """
  Use case for saving a user's strava tokens.
  """

  alias Ecto.{Changeset, Multi}
  alias YTD.Repo
  alias YTD.Strava.Tokens
  alias YTD.Users.{Queries, User}

  @spec call(Tokens.t()) :: Multi.t()
  def call(tokens) do
    change =
      Changeset.change(
        tokens.athlete_id |> Queries.get_user_from_athlete_id() |> Repo.one() ||
          %User{athlete_id: tokens.athlete_id},
        access_token: tokens.access_token,
        refresh_token: tokens.refresh_token
      )

    Multi.insert_or_update(Multi.new(), :save_tokens, change)
  end
end
