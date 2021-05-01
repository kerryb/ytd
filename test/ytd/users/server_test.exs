defmodule YTD.Users.ServerTest do
  use YTD.DataCase, async: false

  alias Phoenix.PubSub
  alias Strava.DetailedAthlete
  alias YTD.Repo
  alias YTD.Users.{Server, User}

  require Ecto.Query

  describe "YTD.Users.Server on receiving {:update_name, user} on the 'users' channel" do
    setup do
      {:ok, _pid} = start_supervised(Server)
      :ok
    end

    test "broadcasts a get_athlete_details message, with the athlete ID, to the strava channel" do
      user = insert(:user)
      PubSub.subscribe(:ytd, "strava")
      PubSub.broadcast!(:ytd, "users", {:update_name, user})
      assert_receive {:get_athlete_details, ^user}
    end
  end

  describe "YTD.Users.Server on receiving {:athlete, athlete} on the 'users' channel" do
    setup do
      {:ok, _pid} = start_supervised(Server)
      user = insert(:user, name: "Fred Bloggs")
      {:ok, user: user}
    end

    test "broadcasts a name_updated message, with the user, to the user channel if the name has changed",
         %{user: user} do
      athlete = %DetailedAthlete{firstname: "Freddy", lastname: "Bloggs"}
      PubSub.subscribe(:ytd, "user:#{user.id}")
      PubSub.broadcast!(:ytd, "users", {:athlete, user, athlete})
      assert_receive {:name_updated, %User{name: "Freddy Bloggs"}}
    end

    test "doesn't broadcast a name_updated message if the name has not changed", %{user: user} do
      athlete = %DetailedAthlete{firstname: "Fred", lastname: "Bloggs"}
      PubSub.subscribe(:ytd, "user:#{user.id}")
      PubSub.broadcast!(:ytd, "users", {:athlete, user, athlete})
      refute_receive {:name_updated, _}
    end

    test "updates the user if the name has changed", %{user: user} do
      athlete = %DetailedAthlete{firstname: "Freddy", lastname: "Bloggs"}
      PubSub.subscribe(:ytd, "user:#{user.id}")
      PubSub.broadcast!(:ytd, "users", {:athlete, user, athlete})
      assert_receive {:name_updated, _user}
      updated_user = Repo.get(User, user.id)
      assert updated_user.name == "Freddy Bloggs"
    end
  end
end
