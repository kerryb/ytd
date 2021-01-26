defmodule YTD.Users.Create do
  @moduledoc """
  Use case for saving a new user, with Strava tokens.
  """

  alias Ecto.Multi
  alias YTD.Strava.Tokens
  alias YTD.Users.User

  @spec call(Tokens.t()) :: Multi.t()
  def call(tokens) do
    user = %User{
      athlete_id: tokens.athlete_id,
      access_token: tokens.access_token,
      refresh_token: tokens.refresh_token
    }

    Multi.insert(Multi.new(), :save_tokens, user)
  end
end
