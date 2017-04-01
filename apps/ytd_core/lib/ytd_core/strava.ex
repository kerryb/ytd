defmodule YTDCore.Strava do
  def ytd(token) do
    client = Strava.Client.new token
    %{id: id} = Strava.Athlete.retrieve_current client
    %{ytd_run_totals: %{distance: distance}} = Strava.Athlete.stats id, client
    metres_to_miles distance
  end

  defp metres_to_miles(metres), do: metres / 1609.34
end
