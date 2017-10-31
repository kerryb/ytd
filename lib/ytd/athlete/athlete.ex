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
