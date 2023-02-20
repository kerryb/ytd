defmodule YTD.Activities.WeekGroup do
  @moduledoc """
  A struct holding the `YTD.Activities.Activity` records for a week, organised
  by day.
  """
  use Boundary, top_level?: false

  alias YTD.Activities.Activity

  @enforce_keys [:from, :to, :day_activities]
  defstruct [:from, :to, :day_activities]
  @type t :: %__MODULE__{from: Date.t(), to: Date.t(), day_activities: %{Date.t() => [Activity]}}
end
