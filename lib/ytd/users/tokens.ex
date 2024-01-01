defmodule YTD.Users.Tokens do
  @moduledoc """
  Context to handle update of expired tokens from Strava. Separated out from
  `YTD.Users` as its own boundary so we can enforce that this is the only
  access from the `YTD.Strava` context to User functions.
  """

  use Boundary, top_level?: true, deps: [Ecto, YTD.{Repo, Users}]

  alias YTD.Repo
  alias YTD.Users.UpdateTokens
  alias YTD.Users.User

  @spec update_user_tokens(
          user :: User.t(),
          access_token :: String.t(),
          refresh_token :: String.t()
        ) :: :ok
  def update_user_tokens(user, access_token, refresh_token) do
    {:ok, _result} =
      user
      |> UpdateTokens.call(access_token, refresh_token)
      |> Repo.transaction()

    :ok
  end
end
