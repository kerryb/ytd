defmodule YTD.Users.Queries do
  @moduledoc """
  Queries for the `YTD.Users.User` schema.
  """

  import Ecto.Query

  alias Ecto.Query
  alias YTD.Users.User

  @spec get_user_from_athlete_id(integer()) :: Query.t()
  def get_user_from_athlete_id(athlete_id) do
    from(u in User, where: u.athlete_id == ^athlete_id)
  end
end
