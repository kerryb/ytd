defmodule YTD.Strava.API do
  @moduledoc """
  API behaviour for the Strava context.
  """

  alias Strava.{DetailedAthlete, SummaryActivity}
  alias YTD.Strava.Tokens
  alias YTD.Users.User

  @callback authorize_url :: String.t() | no_return()
  @callback get_tokens_from_code(code :: String.t()) :: Tokens.t()
  @callback stream_activities_since(
              user :: User.t(),
              timestamp :: DateTime.t(),
              callback :: (SummaryActivity -> any())
            ) :: :ok
  @callback get_athlete_details(user :: User.t()) :: {:ok, DetailedAthlete.t()} | {:error, any()}
  @callback subscribe_to_events :: {:ok, integer()} | {:error, any()}
end
