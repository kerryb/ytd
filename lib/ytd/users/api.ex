defmodule YTD.Users.API do
  @moduledoc """
  API behaviour for the Users context.
  """

  alias Ecto.Multi
  alias YTD.Strava.Tokens
  alias YTD.Users.User

  @callback get_user_from_athlete_id(integer()) :: User.t() | nil

  @callback save_user_tokens(Tokens.t()) ::
              {:ok, any()}
              | {:error, any()}
              | {:error, Multi.name(), any(), %{required(Multi.name()) => any()}}
end
