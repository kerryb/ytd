defmodule YTD.Users do
  @moduledoc """
  Context for interacting with stored users.
  """
  import Ecto.Query

  alias Ecto.Changeset
  alias YTD.Repo
  alias YTD.Users.User

  @spec get_user_from_athlete_id(String.t()) :: User.t() | nil
  def get_user_from_athlete_id(athlete_id) do
    Repo.one(from(u in User, where: u.athlete_id == ^athlete_id))
  end

  @spec save_tokens(String.t(), String.t(), String.t()) :: User.t() | no_return()
  def save_tokens(athlete_id, access_token, refresh_token) do
    user = get_user_from_athlete_id(athlete_id) || %User{}

    user
    |> Changeset.change(access_token: access_token, refresh_token: refresh_token)
    |> Repo.insert_or_update!()
  end
end
