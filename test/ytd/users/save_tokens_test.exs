defmodule YTD.Users.SaveTokensTest do
  use YTD.DataCase

  alias YTD.Repo
  alias YTD.Users.{SaveTokens, User}

  require Ecto.Query

  describe "YTD.Users.SaveTokens.call/3" do
    test "returns a multi that inserts a record with strava ID and tokens for a new user" do
      Repo.transaction(SaveTokens.call(123, "456", "789"))

      assert %{athlete_id: 123, access_token: "456", refresh_token: "789"} =
               Repo.one(from(u in User))
    end

    test "returns a multi that updates strava ID and tokens for an existing user" do
      insert(:user, athlete_id: 123)

      Repo.transaction(SaveTokens.call(123, "456", "789"))

      assert %{athlete_id: 123, access_token: "456", refresh_token: "789"} =
               Repo.one(from(u in User))
    end
  end
end
