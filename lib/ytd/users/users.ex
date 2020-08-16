defmodule YTD.Users do
  import Ecto.Query

  alias YTD.Users.User
  alias YTD.Repo

  def get_user_from_athlete_id(athlete_id) do
    Repo.one(from(u in User, where: u.athlete_id == ^athlete_id))
  end

  def save_tokens(athlete_id, access_token, refresh_token) do
    user = get_user_from_athlete_id(athlete_id) || %User{}

    user
    |> Changeset.change(access_token: access_token, refresh_token: refresh_token)
    |> Repo.insert_or_update!()
  end
end
