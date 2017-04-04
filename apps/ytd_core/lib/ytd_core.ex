defmodule YTDCore do
  @moduledoc """
  Public interface.
  """

  alias YTDCore.{Calculations, Data, Strava}

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
    ytd = Strava.ytd(token)
    %Data{
      ytd: ytd,
      projected_annual: Calculations.projected_annual(ytd, Date.utc_today),
      weekly_average: Calculations.weekly_average(ytd, Date.utc_today),
    }
  end
end
