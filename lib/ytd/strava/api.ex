defmodule YTD.Strava.API do
  @moduledoc """
  API behaviour for the Strava context.
  """

  alias YTD.Strava.Tokens

  @callback authorize_url :: String.t() | no_return()

  @callback get_tokens_from_code(String.t()) :: Tokens.t()
end
