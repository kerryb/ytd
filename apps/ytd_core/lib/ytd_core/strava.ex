defmodule YTDCore.Strava do
  @moduledoc false

  alias Strava.{Auth, Client}
  alias YTDCore.Database.Athlete
  alias YTDCore.Friend

  @spec athlete_from_code(String.t) :: %Athlete{}
  def athlete_from_code(code) do
    %{token: %{access_token: token, other_params: other_params}} =
      Auth.get_token! code: code
    id = other_params["athlete"]["id"]
    %Athlete{id: id, token: token}
  end

  @spec ytd(%YTDCore.Database.Athlete{}) :: float
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

  def friends(%Athlete{token: token, id: id}) do
    client = Client.new token
    Strava.Athlete.friends(id, client)
    |> Enum.map(fn f -> build_friend f, client end)
  end

  defp build_friend(athlete, client) do
    IO.inspect athlete.id
    IO.inspect client
    name = "#{athlete.firstname} #{athlete.lastname}"
    profile_url = "https://www.strava.com/athletes/#{athlete.id}"
    ytd = athlete.id
          |> Strava.Athlete.stats(client)
          |> get_in([:ytd_run_totals, :distance])
          |> metres_to_miles
    %Friend{name: name, profile_url: profile_url, ytd: ytd}
  end

  defp metres_to_miles(metres), do: metres / 1609.34
end
