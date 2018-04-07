defmodule YTD.Athletes do
  @moduledoc """
  API for interacting with athletes. Some data comes from the database, and
  some from Strava.
  """

  require Logger
  import Ecto.Query
  alias Ecto.Changeset
  alias YTD.Athletes.{Athlete, Data, Values}
  alias YTD.{Repo, Strava}

  @doc """
  Given a Strava authorization code (from an oauth callback), request and
  return the corresponding athlete ID.
  """
  @spec find_or_register(String.t()) :: integer
  def find_or_register(code) do
    athlete = Strava.athlete_from_code(code)
    unless find_by_strava_id(athlete.strava_id), do: register(athlete)
    athlete.strava_id
  end

  @doc """
  Register a new athlete, given their Strava ID and API token.
  """
  @spec register(%Athlete{}) :: :ok
  def register(athlete) do
    Logger.info(fn -> "Registering athlete #{inspect(athlete)}" end)
    Repo.insert(athlete)
  end

  @doc """
  Return the athlete with the supplied ID, or nil if not found.
  """
  @spec find_by_strava_id(integer) :: %Athlete{} | nil
  def find_by_strava_id(id) do
    from(a in Athlete, where: a.strava_id == ^id) |> Repo.one()
  end

  @doc """
  Given a Strava athlete ID, returns a `YTD.Athletes.Data` struct with the
  values to be displayed
  """
  @spec values(integer) :: %Data{} | nil
  def values(strava_id) do
    strava_id
    |> find_by_strava_id()
    |> data_for_athlete()
  end

  defp data_for_athlete(nil), do: nil

  defp data_for_athlete(athlete) do
    profile_url = "https://www.strava.com/athletes/#{athlete.strava_id}"
    ytd = Strava.ytd(athlete)

    %Data{
      profile_url: profile_url,
      run: Values.new(ytd.run, athlete.run_target),
      ride: Values.new(ytd.ride, athlete.ride_target),
      swim: Values.new(ytd.swim, athlete.swim_target)
    }
  end

  @doc """
  Store a target mileage for the athlete with the specified ID.
  """
  @spec set_run_target(integer, integer | nil) :: :ok
  def set_run_target(id, 0), do: set_run_target(id, nil)

  def set_run_target(id, target) do
    id
    |> find_by_strava_id()
    |> Changeset.change(run_target: target)
    |> Repo.update()

    :ok
  end

  @doc """
  Store a target mileage for the athlete with the specified ID.
  """
  @spec set_ride_target(integer, integer | nil) :: :ok
  def set_ride_target(id, 0), do: set_ride_target(id, nil)

  def set_ride_target(id, target) do
    id
    |> find_by_strava_id()
    |> Changeset.change(ride_target: target)
    |> Repo.update()

    :ok
  end

  @doc """
  Store a target mileage for the athlete with the specified ID.
  """
  @spec set_swim_target(integer, integer | nil) :: :ok
  def set_swim_target(id, 0), do: set_swim_target(id, nil)

  def set_swim_target(id, target) do
    id
    |> find_by_strava_id()
    |> Changeset.change(swim_target: target)
    |> Repo.update()

    :ok
  end
end
