defmodule YTDCore.Strava do
  @moduledoc false

  alias Strava.{Auth, Client, Athlete}

  @spec token_from_code(String.t) :: String.t
  def token_from_code(code) do
    %{token: %{access_token: token}} = Auth.get_token! code: code
    token
  end

  @spec ytd(String.t) :: float
  def ytd(token) do
    client = Client.new token
    %{id: id} = Athlete.retrieve_current client
    %{ytd_run_totals: %{distance: distance}} = Athlete.stats id, client
    metres_to_miles distance
  end

  defp metres_to_miles(metres), do: metres / 1609.34
end
