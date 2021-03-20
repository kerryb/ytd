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

  describe "YTD.Users.get_targets/1" do
    test "retreives all targets for a user" do
      user = insert(:user, athlete_id: 123)
      insert(:target, user: user, activity_type: "Ride", target: 2000, unit: "km")
      insert(:target, user: user, activity_type: "Run", target: 1000, unit: "miles")

      assert %{"Ride" => %{target: 2000, unit: "km"}, "Run" => %{target: 1000, unit: "miles"}} =
               Users.get_targets(user)
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

  describe "YTD.Users.update_user_tokens/2" do
    test "updates strava tokens for an existing user" do
      user = insert(:user, athlete_id: 123, access_token: "456", refresh_token: "789")

      Users.update_user_tokens(user, %{
        token: %{access_token: "987", refresh_token: "654"}
      })

      assert %{access_token: "987", refresh_token: "654"} = Repo.one(from(u in User))
    end
  end

  describe "YTD.Users.save_activity_type/2" do
    test "updates the saved type" do
      user = insert(:user, athlete_id: 123, selected_activity_type: "Run")
      Users.save_activity_type(user, "Ride")
      assert %{selected_activity_type: "Ride"} = Repo.one(from(u in User))
    end
  end

  describe "YTD.Users.save_unit/2" do
    test "updates the saved unit" do
      user = insert(:user, athlete_id: 123, selected_unit: "miles")
      Users.save_unit(user, "km")
      assert %{selected_unit: "km"} = Repo.one(from(u in User))
    end
  end

  describe "YTD.Users.save_target/2" do
    test "saves a target" do
      user = insert(:user, athlete_id: 123)
      Users.save_target(user, "Run", "1000", "miles")

      assert %{target: 1000, unit: "miles"} = Repo.one(Ecto.assoc(user, :targets))
    end
  end
end
