defmodule YTD.Strava do
  @moduledoc false

  require Logger
  alias Strava.{Auth, Client}
  alias YTD.Database.Athlete

  @spec athlete_from_code(String.t) :: %Athlete{}
  def athlete_from_code(code) do
    %{token: %{access_token: token, other_params: other_params}} =
      Auth.get_token! code: code
    id = other_params["athlete"]["id"]
    %Athlete{id: id, token: token}
  end

  @spec ytd(%Athlete{}) :: float
  def ytd(%Athlete{token: token}) do
    client = Client.new token
    distance = try do
      %Strava.Athlete{id: id} = Strava.Athlete.retrieve_current client
      Strava.Athlete.stats(id, client).ytd_run_totals.distance
    rescue
      _ -> 0.0
    end
    metres_to_miles distance
  end
  def ytd(athlete) do
    Logger.error fn -> "Unexpected athlete: #{inspect athlete}" end
    raise "Unexpected athlete"
  end

  defp metres_to_miles(metres), do: metres / 1609.34
end
