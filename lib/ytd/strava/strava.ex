defmodule YTD.Strava do
  @moduledoc false

  alias Strava.{Auth, Client}
  alias YTD.Athletes.Athlete

  @spec athlete_from_code(String.t()) :: %Athlete{}
  def athlete_from_code(code) do
    %{token: %{access_token: token, other_params: other_params}} = Auth.get_token!(code: code)
    id = other_params["athlete"]["id"]
    %Athlete{strava_id: id, token: token}
  end

  @spec ytd(%Athlete{}) :: %{run: float, ride: float, swim: float}
  def ytd(%Athlete{token: token}) do
    client = Client.new(token)
    %Strava.Athlete{id: id} = Strava.Athlete.retrieve_current(client)
    stats = Strava.Athlete.stats(id, client)

    %{
      run: metres_to_miles(stats.ytd_run_totals.distance),
      ride: metres_to_miles(stats.ytd_ride_totals.distance),
      swim: metres_to_miles(stats.ytd_swim_totals.distance)
    }
  end

  defp metres_to_miles(metres), do: metres / 1609.34
end
