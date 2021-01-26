defmodule YTD.Users.UpdateTokens do
  @moduledoc """
  Use case for updating a user's Strava tokens.
  """

  alias Ecto.{Changeset, Multi}
  alias YTD.Strava.Tokens
  alias YTD.Users.User

  @spec call(User.t(), Tokens.t()) :: Multi.t()
  def call(user, tokens) do
    change =
      Changeset.change(
        user,
        access_token: tokens.access_token,
        refresh_token: tokens.refresh_token
      )

    Multi.update(Multi.new(), :save_tokens, change)
  end
end
