defmodule YTD.Users.CreateTest do
  use YTD.DataCase, async: true

  alias YTD.Repo
  alias YTD.Strava.Tokens
  alias YTD.Users.Create
  alias YTD.Users.User

  require Ecto.Query

  describe "YTD.Users.Create.call/1" do
    test "returns a multi that inserts a record with strava ID and tokens for a new user" do
      tokens = %Tokens{athlete_id: 123, access_token: "456", refresh_token: "789"}
      tokens |> Create.call() |> Repo.transaction()

      assert %{athlete_id: 123, access_token: "456", refresh_token: "789"} =
               Repo.one(from(u in User))
    end
  end
end
