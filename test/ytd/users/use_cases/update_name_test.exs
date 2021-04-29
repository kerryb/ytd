defmodule YTD.Users.UpdateNameTest do
  use YTD.DataCase, async: true

  alias YTD.Repo
  alias YTD.Users.{UpdateName, User}

  require Ecto.Query

  describe "YTD.Users.UpdateName.call/2" do
    test "returns a multi that updates tokens for an existing user" do
      user = insert(:user, name: "Fred Bloggs")

      user
      |> UpdateName.call("Freddy Bloggs")
      |> Repo.transaction()

      assert %{name: "Freddy Bloggs"} = Repo.one(from(u in User))
    end
  end
end
