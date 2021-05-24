defmodule YTD.Strava.API do
  @moduledoc """
  API behaviour for the Strava context.
  """

  alias Strava.DetailedAthlete
  alias YTD.Strava.Tokens
  alias YTD.Users.User

  @callback authorize_url :: String.t() | no_return()
  @callback get_tokens_from_code(code :: String.t()) :: Tokens.t()
  @callback stream_activities_since(pid :: pid(), user :: User.t(), timestamp :: DateTime.t()) ::
              :ok
  @callback get_athlete_details(user :: User.t()) :: {:ok, DetailedAthlete.t()} | {:error, any()}
end
