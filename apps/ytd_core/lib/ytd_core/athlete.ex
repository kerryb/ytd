defmodule YTDCore.Athlete do
  @moduledoc """
  Stores details of athletes, keyed by athlete ID. This is not intended to hold
  any data that can be obtained from Strava, but only application-specific
  values (currently only the API token).
  """

  require Logger

  @type t :: %__MODULE__{id: integer, token: String.t}
  defstruct [:id, :token]

  def start_link, do: Agent.start_link fn -> %{} end, name: __MODULE__

  @doc """
  Register a new athlete, given their Strava ID and API token.
  """
  @spec register(%YTDCore.Athlete{}) :: :ok
  def register(athlete) do
    Logger.info "Registering athlete #{inspect athlete}"
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
end
