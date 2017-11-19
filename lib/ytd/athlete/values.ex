defmodule YTD.Athlete.Values do
  @moduledoc """
  A struct holding the YTD and calculated values for a particular sport.
  """

  alias YTD.Athlete.Calculations

  @type t :: %__MODULE__{
    ytd: float,
    units: String.t,
    projected_annual: float,
    weekly_average: float,
    target: integer,
    estimated_target_completion: Date.t,
    on_target?: boolean,
    required_average: float,
  }
  defstruct [
    :ytd,
    :units,
    :projected_annual,
    :weekly_average,
    :target,
    :estimated_target_completion,
    :on_target?,
    :required_average,
  ]

  @spec new(float, integer) :: %__MODULE__{}
  def new(ytd, target) do
    projected_annual = Calculations.projected_annual ytd, Date.utc_today
    weekly_average = Calculations.weekly_average ytd, Date.utc_today
    on_target? = Calculations.on_target?(ytd, Date.utc_today, target)
    required_average = Calculations.required_average(
      ytd, Date.utc_today, target)
    %__MODULE__{
      ytd: ytd,
      target: target,
      projected_annual: projected_annual,
      weekly_average: weekly_average,
      estimated_target_completion: estimated_completion(ytd, target),
      on_target?: on_target?,
      required_average: required_average,
    }
  end

  # TODO: push down
  defp estimated_completion(ytd, target) do
    Calculations.estimated_target_completion(ytd, Date.utc_today, target)
  end
end
