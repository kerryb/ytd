defmodule YTD.Users.UpdateTokensTest do
  use YTD.DataCase, async: true

  alias YTD.Repo
  alias YTD.Users.{UpdateTokens, User}

  require Ecto.Query

  describe "YTD.Users.UpdateTokens.call/2" do
    test "returns a multi that updates tokens for an existing user" do
      user = insert(:user, athlete_id: 123)

      user
      |> UpdateTokens.call("456", "789")
      |> Repo.transaction()

      assert %{access_token: "456", refresh_token: "789"} = Repo.one(from(u in User))
    end
  end
end
