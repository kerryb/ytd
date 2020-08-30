defmodule YTD.Users.SaveTokens do
  @moduledoc """
  Use case for saving a user's strava tokens
  """

  alias Ecto.{Changeset, Multi}
  alias YTD.Repo
  alias YTD.Users.{Queries, User}

  @spec call(String.t(), String.t(), String.t()) :: Multi.t()
  def call(athlete_id, access_token, refresh_token) do
    change =
      Changeset.change(
        athlete_id |> Queries.get_user_from_athlete_id() |> Repo.one() || %User{},
        access_token: access_token,
        refresh_token: refresh_token
      )

    Multi.insert_or_update(Multi.new(), :save_tokens, change)
  end
end
