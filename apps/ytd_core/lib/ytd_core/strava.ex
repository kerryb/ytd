defmodule YTDCore.Strava do
  @moduledoc false

  alias Strava.{Auth, Client}
  alias YTDCore.Athlete

  @spec athlete_from_code(String.t) :: %YTDCore.Athlete{}
  def athlete_from_code(code) do
    %{token: %{access_token: token, other_params: other_params}} =
      Auth.get_token! code: code
    id = other_params["athlete"]["id"]
    %Athlete{id: id, token: token}
  end

  @spec ytd(%YTDCore.Athlete{}) :: float
  def ytd(%Athlete{token: token}) do
    client = Client.new token
    %{id: id} = Strava.Athlete.retrieve_current client
    %{ytd_run_totals: %{distance: distance}} = Strava.Athlete.stats id, client
    metres_to_miles distance
  end

  defp metres_to_miles(metres), do: metres / 1609.34
end
