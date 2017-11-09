defmodule YTD.Athlete.Data do
  @moduledoc """
  A struct holding the data to be displayed for an athlete.
  """

  @type t :: %__MODULE__{profile_url: String.t,
                         ytd: float,
                         projected_annual: float,
                         weekly_average: float,
                         target: integer,
                         estimated_target_completion: Date.t,
                         on_target?: boolean,
                         required_average: float,
                       }
  defstruct [
    :profile_url,
    :ytd,
    :projected_annual,
    :weekly_average,
    :target,
    :estimated_target_completion,
    :on_target?,
    :required_average,
  ]
end
