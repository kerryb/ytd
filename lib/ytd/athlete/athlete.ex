defmodule YTD.Athlete do
  @moduledoc """
  Stores details of athletes, keyed by athlete ID. This is not intended to hold
  any data that can be obtained from Strava, but only application-specific
  values (currently only the API token and annual mileage target).

  These functions are a wrapper for the Amnesia table
  `YTD.Database.Athlete`.
  """

  require Amnesia
  require Amnesia.Helper
  require Logger
  alias YTD.Database.Athlete, as: DBAthlete
  alias YTD.Athlete.{Calculations, Data}
  alias YTD.Strava

  @doc """
  Given a Strava authorization code (from an oauth callback), request and
  return the corresponding athlete ID.
  """
  @spec find_or_register(String.t) :: integer
  def find_or_register(code) do
    athlete = Strava.athlete_from_code(code)
    unless find(athlete.id), do: register athlete
    athlete.id
  end

  @doc """
  Register a new athlete, given their Strava ID and API token.
  """
  @spec register(%DBAthlete{}) :: :ok
  def register(athlete) do
    Logger.info fn -> "Registering athlete #{inspect athlete}" end
    Amnesia.transaction do
      DBAthlete.write athlete
    end
  end

  @doc """
  Return the athlete with the supplied ID, or nil if not found.
  """
  @spec find(integer) :: %DBAthlete{} | nil
  def find(id) do
    Amnesia.transaction do
      DBAthlete.read id
    end
  end

  @doc """
  Given an athlete ID, returns a `YTD.Athlete.Data` struct with the values to be
  displayed
  """
  @spec values(integer) :: %Data{} | nil
  def values(athlete_id) do
    case find(athlete_id) do
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
  Store a target mileage for the athlete with the specified ID.
  """
  @spec set_target(integer, integer) :: :ok
  def set_target(id, target) do
    Amnesia.transaction do
      id
      |> DBAthlete.read
      |> Map.put(:target, target)
      |> DBAthlete.write
    end
    :ok
  end
end
