defmodule YTD.Strava do
  @moduledoc false

  alias Ecto.Changeset
  alias Strava.{Athletes, Auth, Client}
  alias YTD.Athletes.Athlete
  alias YTD.Repo

  @spec athlete_from_code(String.t()) :: %Athlete{}
  def athlete_from_code(code) do
    %{
      token: %{
        access_token: access_token,
        refresh_token: refresh_token,
        other_params: other_params
      }
    } = Auth.get_token!(code: code)

    id = other_params["athlete"]["id"]
    %Athlete{strava_id: id, access_token: access_token, refresh_token: refresh_token}
  end

  @spec ytd(%Athlete{}) :: %{run: float, ride: float, swim: float}
  def ytd(athlete) do
    client =
      Client.new(athlete.access_token,
        refresh_token: athlete.refresh_token,
        token_refreshed: &update_tokens(&1, athlete)
      )
      |> IO.inspect()

    {:ok, %{id: id}} = Athletes.get_logged_in_athlete(client)
    {:ok, stats} = Athletes.get_stats(client, id)

    %{
      run: metres_to_miles(stats.ytd_run_totals.distance),
      ride: metres_to_miles(stats.ytd_ride_totals.distance),
      swim: metres_to_miles(stats.ytd_swim_totals.distance)
    }
  end

  defp update_tokens(client, athlete) do
    IO.inspect(client)

    athlete
    |> Changeset.change(
      access_token: client.token.access_token,
      refresh_token: client.token.refresh_token
    )
    |> Repo.update!()
  end

  defp metres_to_miles(metres), do: metres / 1609.34
end
