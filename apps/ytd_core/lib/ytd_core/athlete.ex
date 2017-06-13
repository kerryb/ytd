defmodule YTDCore.Athlete do
  @moduledoc """
  Stores details of athletes, keyed by athlete ID. This is not intended to hold
  any data that can be obtained from Strava, but only application-specific
  values (currently only the API token and annual mileage target).

  These functions are a wrapper for the Amnesia table
  `YTDCore.Database.Athlete`.
  """

  require Amnesia
  require Amnesia.Helper
  require Logger
  alias YTDCore.Database

  @type t :: %__MODULE__{id: integer, token: String.t, target: integer}
  defstruct [:id, :token, :target]

  @doc """
  Register a new athlete, given their Strava ID and API token.
  """
  @spec register(%YTDCore.Athlete{}) :: :ok
  def register(athlete) do
    Logger.info fn -> "Registering athlete #{inspect athlete}" end
    Amnesia.transaction do
      Database.Athlete.write struct(Database.Athlete, Map.from_struct athlete)
    end
  end

  @doc """
  Return the athlete with the supplied ID, or nil if not found.
  """
  @spec find(integer) :: %YTDCore.Athlete{} | nil
  def find(id) do
    Amnesia.transaction do
      struct YTDCore.Athlete, Map.from_struct(Database.Athlete.read id)
    end
  end

  @doc """
  Store a target mileage for the athlete with the specified ID.
  """
  @spec set_target(integer, integer) :: :ok
  def set_target(id, target) do
    Amnesia.transaction do
      id
      |> Database.Athlete.read
      |> Map.put(:target, target)
      |> Database.Athlete.write
    end
    :ok
  end
end
