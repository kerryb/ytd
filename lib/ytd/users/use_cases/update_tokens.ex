defmodule YTD.Users.UpdateTokens do
  @moduledoc """
  Use case for updating a user's Strava tokens.
  """

  alias Ecto.Changeset
  alias Ecto.Multi
  alias YTD.Users.User

  @spec call(User.t(), String.t(), String.t()) :: Multi.t()
  def call(user, access_token, refresh_token) do
    change = Changeset.change(user, access_token: access_token, refresh_token: refresh_token)
    Multi.update(Multi.new(), :update_tokens, change)
  end
end
