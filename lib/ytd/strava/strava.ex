defmodule YTD.Strava do
  @moduledoc """
  Wrapper for calls to the Strava API.
  """

  @behaviour YTD.Strava.API

  alias Strava.Auth
  alias YTD.Strava.Tokens

  @spec authorize_url :: String.t() | no_return()
  def authorize_url do
    Auth.authorize_url!(scope: "activity:read,activity:read_all")
  end

  @spec get_tokens_from_code(String.t()) :: Tokens.t()
  def get_tokens_from_code(code) do
    client = Auth.get_token!(code: code, grant_type: "authorization_code")
    Tokens.new(client)
  end
end
