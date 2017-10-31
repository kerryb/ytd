defmodule YTD.Core do
  @moduledoc """
  Public interface.
  """

  alias YTD.Athlete

  @doc """
  Sets the annual mileage target for the athlete with the specified ID
  """
  @spec set_target(integer, integer) :: :ok
  def set_target(athlete_id, target) do
    Athlete.set_target athlete_id, target
  end
end
