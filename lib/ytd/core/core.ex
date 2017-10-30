defmodule YTD.Core do
  @moduledoc """
  Public interface.
  """

  alias YTD.Database.Athlete, as: DBAthlete
  alias YTD.{Athlete, Strava}
  alias YTD.Athlete.Data
  alias YTD.Core.Calculations

  @doc """
  Given an authorization code (from an oauth callback), request and return the
  corresponding athlete ID.
  """
  @spec find_or_register(String.t) :: integer
  def find_or_register(code) do
    athlete = Strava.athlete_from_code(code)
    unless Athlete.find(athlete.id), do: Athlete.register athlete
    athlete.id
  end

  @doc """
  Given an athlete ID, returns a `YTD.Athlete.Data` struct with the values to be
  displayed
  """
  @spec values(integer) :: %Athlete.Data{} | nil
  def values(athlete_id) do
    case Athlete.find(athlete_id) do
      nil -> nil
      athlete ->
        profile_url = "https://www.strava.com/athletes/#{athlete_id}"
        ytd = Strava.ytd athlete
        projected_annual = Calculations.projected_annual ytd, Date.utc_today
        weekly_average = Calculations.weekly_average ytd, Date.utc_today
        %Data{
          profile_url: profile_url,
          ytd: ytd,
          target: athlete.target,
          projected_annual: projected_annual,
          weekly_average: weekly_average,
          extra_needed_today: extra_needed_today(athlete, ytd),
          extra_needed_this_week: extra_needed_this_week(athlete, ytd),
          estimated_target_completion: estimated_completion(athlete, ytd),
        }
    end
  end

  defp extra_needed_today(%DBAthlete{target: nil}, _), do: nil
  defp extra_needed_today(athlete, ytd) do
    Calculations.extra_needed_today(ytd, Date.utc_today, athlete.target)
  end

  defp extra_needed_this_week(%DBAthlete{target: nil}, _), do: nil
  defp extra_needed_this_week(athlete, ytd) do
    Calculations.extra_needed_this_week(ytd, Date.utc_today,
                                        athlete.target, 1)
  end

  defp estimated_completion(%DBAthlete{target: nil}, _), do: nil
  defp estimated_completion(athlete, ytd) do
    Calculations.estimated_target_completion ytd, Date.utc_today, athlete.target
  end

  @doc """
  Sets the annual mileage target for the athlete with the specified ID
  """
  @spec set_target(integer, integer) :: :ok
  def set_target(athlete_id, target) do
    Athlete.set_target athlete_id, target
  end
end
