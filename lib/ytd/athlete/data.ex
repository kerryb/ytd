defmodule YTD.Athlete.Data do
  @moduledoc """
  A struct holding the data to be displayed for an athlete.
  """

  @type t :: %__MODULE__{profile_url: String.t,
                         ytd: float,
                         projected_annual: float,
                         weekly_average: float,
                         target: integer,
                         extra_needed_today: float,
                         extra_needed_this_week: float,
                         estimated_target_completion: Date.t,
                       }
  defstruct [:profile_url, :ytd, :projected_annual, :weekly_average,
             :target, :extra_needed_today, :extra_needed_this_week,
             :estimated_target_completion]
end
