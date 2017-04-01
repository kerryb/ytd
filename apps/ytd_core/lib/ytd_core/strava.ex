defmodule YTDCore.Strava do
  @moduledoc """
  Wrapper for calls to the Strava API.
  """

  alias Strava.{Client, Athlete}

  @doc """
  Given an access token for an athlete, retrieve their year-to-data mileage.
  """
  def ytd(token) do
    client = Client.new token
    %{id: id} = Athlete.retrieve_current client
    %{ytd_run_totals: %{distance: distance}} = Athlete.stats id, client
    metres_to_miles distance
  end

  defp metres_to_miles(metres), do: metres / 1609.34
end
