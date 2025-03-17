defmodule YTD.UsersTokensTest do
  use YTD.DataCase

  alias YTD.Repo
  alias YTD.Strava.Tokens
  alias YTD.Users.Tokens
  alias YTD.Users.User

  describe "YTD.Users.Tokens.update_user_tokens/2" do
    test "updates strava tokens for an existing user" do
      user = insert(:user, athlete_id: 123, access_token: "456", refresh_token: "789")
      :ok = Tokens.update_user_tokens(user, "987", "654")
      assert %{access_token: "987", refresh_token: "654"} = Repo.one(from(u in User))
    end
  end
end
