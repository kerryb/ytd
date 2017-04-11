defmodule YTDCore.Athlete do
  @moduledoc """
  Stores details of athletes, keyed by athlete ID. This is not intended to hold
  any data that can be obtained from Strava, but only application-specific
  values (currently only the API token).
  """

  @type t :: %__MODULE__{id: integer, token: String.t}
  defstruct [:id, :token]

  def start_link, do: Agent.start_link fn -> %{} end, name: __MODULE__

  @doc """
  Register a new athlete, given their Strava ID and API token.
  """
  @spec register(integer, String.t) :: :ok
  def register(id, token) do
    Agent.update __MODULE__, fn athletes ->
      Map.put athletes, id, %__MODULE__{id: id, token: token}
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
