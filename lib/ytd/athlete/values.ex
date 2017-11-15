defmodule YTD.Athlete.Values do
  @moduledoc """
  A struct holding the YTD and calculated values for a particular sport.
  """

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
end
