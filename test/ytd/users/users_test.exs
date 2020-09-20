defmodule YTD.UsersTest do
  use YTD.DataCase, async: true

  alias YTD.{Repo, Users}
  alias YTD.Strava.Tokens
  alias YTD.Users.User

  require Ecto.Query

  describe "YTD.Users.get_user_from_athlete_id/1" do
    test "returns the user with the supplied athlete ID, if found" do
      user = insert(:user, athlete_id: 123)
      assert Users.get_user_from_athlete_id(123) == user
    end

    test "returns nil if no user is found" do
      assert Users.get_user_from_athlete_id(123) == nil
    end
  end

  describe "YTD.Users.save_user_tokens/1" do
    test "returns a multi that inserts a record with strava ID and tokens for a new user" do
      Users.save_user_tokens(%Tokens{athlete_id: 123, access_token: "456", refresh_token: "789"})

      assert %{athlete_id: 123, access_token: "456", refresh_token: "789"} =
               Repo.one(from(u in User))
    end

    test "returns a multi that updates strava ID and tokens for an existing user" do
      insert(:user, athlete_id: 123)

      Users.save_user_tokens(%Tokens{athlete_id: 123, access_token: "456", refresh_token: "789"})

      assert %{athlete_id: 123, access_token: "456", refresh_token: "789"} =
               Repo.one(from(u in User))
    end
  end
end
