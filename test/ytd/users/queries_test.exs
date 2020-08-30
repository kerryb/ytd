defmodule YTD.Users.QueriesTest do
  use YTD.DataCase

  alias YTD.Repo
  alias YTD.Users.Queries

  require Ecto.Query

  describe "YTD.Users.Queries.get_user_from_athlete_id/1" do
    test "returns the user with the supplied athlete ID, if found" do
      user = insert(:user, athlete_id: 123)
      assert Repo.one(Queries.get_user_from_athlete_id(123)) == user
    end

    test "returns nil if no user is found" do
      assert Repo.one(Queries.get_user_from_athlete_id(123)) == nil
    end
  end
end
