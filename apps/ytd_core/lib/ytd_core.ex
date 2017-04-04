defmodule YTDCore do
  @moduledoc """
  Public interface.
  """

  alias YTDCore.{Data, Strava}

  @doc """
  Given an authorization code (from an oauth callback), request and return an
  access token for that athlete.
  """
  def token_from_code(code), do: Strava.token_from_code code

  @doc """
  Returns a `YTDCore.Data` struct with the values to be displayed
  """
  @spec values(String.t) :: %YTDCore.Data{}
  def values(token) do
    %Data{ytd: Strava.ytd(token)}
  end
end
