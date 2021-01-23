defmodule YTD.UsersTest do
  use YTD.DataCase, async: false

  alias Phoenix.PubSub
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
    test "inserts a record with strava ID and tokens for a new user" do
      Users.save_user_tokens(%Tokens{athlete_id: 123, access_token: "456", refresh_token: "789"})

      assert %{athlete_id: 123, access_token: "456", refresh_token: "789"} =
               Repo.one(from(u in User))
    end

    test "updates strava ID and tokens for an existing user" do
      insert(:user, athlete_id: 123)

      Users.save_user_tokens(%Tokens{athlete_id: 123, access_token: "456", refresh_token: "789"})

      assert %{athlete_id: 123, access_token: "456", refresh_token: "789"} =
               Repo.one(from(u in User))
    end
  end

  describe "YTD.Users server on receiving {:token_refreshed, user, token} on the 'users' channel" do
    setup do
      {:ok, _pid} = start_supervised(Users)
      :ok
    end

    test "updates the saved tokens" do
      user = insert(:user, athlete_id: 123)
      PubSub.subscribe(:ytd, "user-updates")

      PubSub.broadcast!(
        :ytd,
        "users",
        {:token_refreshed, user, %{access_token: "456", refresh_token: "789"}}
      )

      assert_receive {:updated, _}
      assert %{access_token: "456", refresh_token: "789"} = Repo.one(from(u in User))
    end
  end
end
