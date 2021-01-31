defmodule YTD.Users.UpdateSelectedUnitTest do
  use YTD.DataCase, async: true

  alias YTD.Repo
  alias YTD.Users.{UpdateSelectedUnit, User}

  require Ecto.Query

  describe "YTD.Users.UpdateSelectedUnit.call/2" do
    test "returns a multi that updates the selected activity type for an existing user" do
      user = insert(:user, athlete_id: 123, selected_unit: "miles")

      user
      |> UpdateSelectedUnit.call("km")
      |> Repo.transaction()

      assert %{selected_unit: "km"} = Repo.one(from(u in User))
    end
  end
end
