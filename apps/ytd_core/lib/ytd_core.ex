defmodule YTDCore do
  @moduledoc """
  Public interface.
  """

  alias YTDCore.{Athlete, Calculations, Data, Strava}

  @doc """
  Given an authorization code (from an oauth callback), request and return the
  corresponding athlete ID.
  """
  @spec register(String.t) :: integer
  def register(code) do
    athlete = Strava.athlete_from_code(code)
    Athlete.register athlete
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
        ytd = Strava.ytd athlete
        projected_annual = Calculations.projected_annual ytd, Date.utc_today
        weekly_average = Calculations.weekly_average ytd, Date.utc_today
        %Data{
          ytd: ytd,
          target: athlete.target,
          projected_annual: projected_annual,
          weekly_average: weekly_average,
          extra_needed_today: extra_needed_today(athlete, ytd),
          extra_needed_this_week: extra_needed_this_week(athlete, ytd),
        }
    end
  end

  defp extra_needed_today(%Athlete{target: nil}, _), do: nil
  defp extra_needed_today(athlete, ytd) do
    Calculations.extra_needed_today(ytd, Date.utc_today, athlete.target)
  end

  defp extra_needed_this_week(%Athlete{target: nil}, _), do: nil
  defp extra_needed_this_week(athlete, ytd) do
    Calculations.extra_needed_this_week(ytd, Date.utc_today,
                                        athlete.target, :mon)
  end
end
