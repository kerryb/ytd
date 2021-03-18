defmodule YTD.Users.SaveTargetTest do
  use YTD.DataCase, async: true

  import Assertions, only: [assert_lists_equal: 3, assert_structs_equal: 3]

  alias YTD.Repo
  alias YTD.Users.{SaveTarget, Target}

  require Ecto.Query

  describe "YTD.Users.SaveTarget.call/4" do
    test "returns a multi that creates a target if none exists for the activity type" do
      user = insert(:user)

      user
      |> SaveTarget.call("Run", "1000", "miles")
      |> Repo.transaction()

      assert [%{activity_type: "Run", target: 1000, unit: "miles"}] =
               Repo.all(Ecto.assoc(user, :targets))
    end

    test "updates the target if one is already set" do
      user = insert(:user)
      insert(:target, user: user, activity_type: "Run", target: 500, unit: "km")

      user
      |> SaveTarget.call("Run", "1000", "miles")
      |> Repo.transaction()

      assert [%{activity_type: "Run", target: 1000, unit: "miles"}] =
               Repo.all(Ecto.assoc(user, :targets))
    end

    test "tracks activity types separately" do
      user = insert(:user)
      insert(:target, user: user, activity_type: "Ride", target: 500, unit: "km")

      user
      |> SaveTarget.call("Run", "1000", "miles")
      |> Repo.transaction()

      assert_lists_equal(
        Repo.all(Ecto.assoc(user, :targets)),
        [
          %Target{activity_type: "Ride", target: 500, unit: "km"},
          %Target{activity_type: "Run", target: 1000, unit: "miles"}
        ],
        &assert_structs_equal(&1, &2, [:activity_type, :target, :unit])
      )
    end
  end
end
