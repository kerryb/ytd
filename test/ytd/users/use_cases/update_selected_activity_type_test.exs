defmodule YTD.Users.UpdateSelectedActivityTypeTest do
  use YTD.DataCase, async: true

  alias YTD.Repo
  alias YTD.Users.UpdateSelectedActivityType
  alias YTD.Users.User

  require Ecto.Query

  describe "YTD.Users.UpdateSelectedActivityType.call/2" do
    test "returns a multi that updates the selected activity type for an existing user" do
      user = insert(:user, athlete_id: 123, selected_activity_type: "Run")

      user
      |> UpdateSelectedActivityType.call("Ride")
      |> Repo.transaction()

      assert %{selected_activity_type: "Ride"} = Repo.one(from(u in User))
    end
  end
end
