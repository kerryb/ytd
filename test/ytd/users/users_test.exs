defmodule YTD.UsersTest do
  use YTD.DataCase, async: true

  import Mox

  alias Phoenix.PubSub
  alias Strava.DetailedAthlete
  alias YTD.{Repo, Users}
  alias YTD.Strava.Tokens
  alias YTD.Users.User

  require Ecto.Query

  defp stub_strava(_context) do
    stub(StravaMock, :get_athlete_details, fn _user -> {:ok, %DetailedAthlete{}} end)
    :ok
  end

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
    test "retrieves all targets for a user" do
      user = insert(:user, athlete_id: 123)
      insert(:target, user: user, activity_type: "Ride", target: 2000, unit: "km")
      insert(:target, user: user, activity_type: "Run", target: 1000, unit: "miles")

      assert %{"Ride" => %{target: 2000, unit: "km"}, "Run" => %{target: 1000, unit: "miles"}} =
               Users.get_targets(user)
    end
  end

  describe "YTD.Users.save_user_tokens/1" do
    test "inserts a record with strava ID and tokens for a new user" do
      :ok =
        Users.save_user_tokens(%Tokens{athlete_id: 123, access_token: "456", refresh_token: "789"})

      assert %{athlete_id: 123, access_token: "456", refresh_token: "789"} =
               Repo.one(from(u in User))
    end

    test "updates strava ID and tokens for an existing user" do
      insert(:user, athlete_id: 123)

      :ok =
        Users.save_user_tokens(%Tokens{athlete_id: 123, access_token: "456", refresh_token: "789"})

      assert %{athlete_id: 123, access_token: "456", refresh_token: "789"} =
               Repo.one(from(u in User))
    end
  end

  describe "YTD.Users.save_activity_type/2" do
    test "updates the saved type" do
      user = insert(:user, athlete_id: 123, selected_activity_type: "Run")
      :ok = Users.save_activity_type(user, "Ride")
      assert %{selected_activity_type: "Ride"} = Repo.one(from(u in User))
    end
  end

  describe "YTD.Users.save_unit/2" do
    test "updates the saved unit" do
      user = insert(:user, athlete_id: 123, selected_unit: "miles")
      :ok = Users.save_unit(user, "km")
      assert %{selected_unit: "km"} = Repo.one(from(u in User))
    end
  end

  describe "YTD.Users.save_target/2" do
    test "saves a target" do
      user = insert(:user, athlete_id: 123)
      :ok = Users.save_target(user, "Run", "1000", "miles")

      assert %{target: 1000, unit: "miles"} = Repo.one(Ecto.assoc(user, :targets))
    end
  end

  describe "YTD.Users.update_name/1" do
    setup do
      user = insert(:user, name: "Fred Bloggs")
      PubSub.subscribe(:ytd, "athlete:#{user.athlete_id}")
      {:ok, user: user}
    end

    setup :stub_strava
    setup :verify_on_exit!

    test "sends a :name_updated message if the name has changed", %{user: user} do
      athlete = %DetailedAthlete{firstname: "Freddy", lastname: "Bloggs"}
      stub(StravaMock, :get_athlete_details, fn ^user -> {:ok, athlete} end)
      :ok = Users.update_name(user)
      assert_receive {:name_updated, %User{name: "Freddy Bloggs"}}
    end

    test "doesn't broadcast a name_updated message if the name has not changed", %{user: user} do
      athlete = %DetailedAthlete{firstname: "Fred", lastname: "Bloggs"}
      stub(StravaMock, :get_athlete_details, fn ^user -> {:ok, athlete} end)
      :ok = Users.update_name(user)
      refute_receive {:name_updated, _}
    end

    test "updates the user if the name has changed", %{user: user} do
      athlete = %DetailedAthlete{firstname: "Freddy", lastname: "Bloggs"}
      stub(StravaMock, :get_athlete_details, fn ^user -> {:ok, athlete} end)
      :ok = Users.update_name(user)
      updated_user = Repo.get(User, user.id)
      assert updated_user.name == "Freddy Bloggs"
    end
  end

  describe "YTD.Users.athlete_updated/1" do
    setup do
      user = insert(:user, name: "Fred Bloggs")
      PubSub.subscribe(:ytd, "athlete:#{user.athlete_id}")
      {:ok, user: user}
    end

    setup :stub_strava
    setup :verify_on_exit!

    test "sends a :name_updated message if the name has changed", %{user: user} do
      athlete = %DetailedAthlete{firstname: "Freddy", lastname: "Bloggs"}
      stub(StravaMock, :get_athlete_details, fn ^user -> {:ok, athlete} end)
      :ok = Users.athlete_updated(user.athlete_id)
      assert_receive {:name_updated, %User{name: "Freddy Bloggs"}}
    end

    test "doesn't broadcast a name_updated message if the name has not changed", %{user: user} do
      athlete = %DetailedAthlete{firstname: "Fred", lastname: "Bloggs"}
      stub(StravaMock, :get_athlete_details, fn ^user -> {:ok, athlete} end)
      :ok = Users.athlete_updated(user.athlete_id)
      refute_receive {:name_updated, _}
    end

    test "updates the user if the name has changed", %{user: user} do
      athlete = %DetailedAthlete{firstname: "Freddy", lastname: "Bloggs"}
      stub(StravaMock, :get_athlete_details, fn ^user -> {:ok, athlete} end)
      :ok = Users.athlete_updated(user.athlete_id)
      updated_user = Repo.get(User, user.id)
      assert updated_user.name == "Freddy Bloggs"
    end
  end

  describe "YTD.Users.athlete_deleted/1" do
    setup do
      user = insert(:user, name: "Fred Bloggs")
      insert(:activity, user: user)
      PubSub.subscribe(:ytd, "athlete:#{user.athlete_id}")
      {:ok, user: user}
    end

    test "deletes the user", %{user: user} do
      :ok = Users.athlete_deleted(user.athlete_id)
      assert Repo.all(User) == []
    end

    test "sends a :deauthorised message", %{user: user} do
      :ok = Users.athlete_deleted(user.athlete_id)
      assert_receive :deauthorised
    end
  end
end
