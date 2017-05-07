defmodule YTDCore.Athlete do
  @moduledoc """
  Stores details of athletes, keyed by athlete ID. This is not intended to hold
  any data that can be obtained from Strava, but only application-specific
  values (currently only the API token).

  Athlete information is only stored in memory, not on disk, so will be lost if
  the application is restarted.
  """

  @vsn "1"

  require Logger

  @type t :: %__MODULE__{id: integer, token: String.t}
  defstruct [:id, :token, :target]

  def start_link, do: Agent.start_link fn -> %{} end, name: __MODULE__

  @doc """
  Register a new athlete, given their Strava ID and API token.
  """
  @spec register(%YTDCore.Athlete{}) :: :ok
  def register(athlete) do
    Logger.info fn -> "Registering athlete #{inspect athlete}" end
    Agent.update __MODULE__, fn athletes ->
      Map.put athletes, athlete.id, athlete
    end
  end

  @doc """
  Return the athlete with the supplied ID, or nil if not found.
  """
  @spec find(integer) :: %YTDCore.Athlete{} | nil
  def find(id) do
    Agent.get __MODULE__, fn athletes -> Map.get athletes, id end
  end

  @doc """
  Store a target mileage for the athlete with the specified ID.
  """
  @spec set_target(integer, integer) :: :ok
  def set_target(id, target) do
    Agent.update __MODULE__, fn athletes ->
      Map.update! athletes, id, fn athlete -> %{athlete | target: target} end
    end
  end

  def code_change(:undefined, athlete, _), do: {:ok, %{athlete | target: nil}}
end
