defmodule YTDCore do
  @moduledoc """
  Public interface.
  """

  alias YTDCore.{Athlete, Calculations, Data, Database, Strava}

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
  Returns a `YTDCore.Data` struct with the values to be displayed
  """
  @spec values(integer) :: %YTDCore.Data{} | nil
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
        }
    end
  end

  defp extra_needed_today(%Database.Athlete{target: nil}, _), do: nil
  defp extra_needed_today(athlete, ytd) do
    Calculations.extra_needed_today(ytd, Date.utc_today, athlete.target)
  end

  defp extra_needed_this_week(%Database.Athlete{target: nil}, _), do: nil
  defp extra_needed_this_week(athlete, ytd) do
    Calculations.extra_needed_this_week(ytd, Date.utc_today,
                                        athlete.target, 1)
  end

  @doc """
  Sets the annual mileage target for the athlete with the specified ID
  """
  @spec set_target(integer, integer) :: :ok
  def set_target(athlete_id, target) do
    Athlete.set_target athlete_id, target
  end
end
