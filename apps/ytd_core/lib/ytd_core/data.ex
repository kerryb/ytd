defmodule YTDCore.Data do
  @moduledoc """
  A struct holding the data to be displayed for an athlete.
  """

  @type t :: %__MODULE__{ytd: float,
                         projected_annual: float,
                         weekly_average: float}
  defstruct [:ytd, :projected_annual, :weekly_average]
end
