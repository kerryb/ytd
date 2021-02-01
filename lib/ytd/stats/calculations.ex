defmodule YTD.Stats do
  @moduledoc """
  Calculate stats based on the total distance, current date and optional
  target.
  """

  @type t :: %__MODULE__{
          weekly_average: float(),
          projected_annual: float(),
          on_target?: boolean() | nil,
          estimated_target_completion: float() | nil,
          required_average: float() | nil
        }

  @enforce_keys [
    :weekly_average,
    :projected_annual
  ]

  defstruct [
    :weekly_average,
    :projected_annual,
    :on_target?,
    :estimated_target_completion,
    :required_average
  ]

  @spec calculate(float(), DateTime.t(), integer() | nil) :: t()
  def calculate(ytd, now, target \\ nil)

  def calculate(ytd, now, nil) do
    %__MODULE__{
      weekly_average: weekly_average(ytd, now),
      projected_annual: projected_annual(ytd, now)
    }
  end

  def calculate(ytd, now, target) do
    %__MODULE__{
      weekly_average: weekly_average(ytd, now),
      projected_annual: projected_annual(ytd, now),
      on_target?: on_target?(ytd, now, target),
      estimated_target_completion: estimated_target_completion(ytd, now, target),
      required_average: required_average(ytd, now, target)
    }
  end

  defp projected_annual(ytd, now) do
    ytd * days_in_year(now) / Timex.day(now)
  end

  defp days_in_year(now), do: if(Timex.is_leap?(now), do: 366, else: 365)

  defp weekly_average(ytd, now) do
    ytd / Timex.day(now) * 7
  end

  defp on_target?(ytd, now, target), do: projected_annual(ytd, now) >= target

  defp estimated_target_completion(_ytd, _now, nil), do: nil
  defp estimated_target_completion(0.0, _now, _target), do: nil

  defp estimated_target_completion(ytd, now, target) do
    days = Timex.day(now)
    Timex.shift(Timex.beginning_of_year(now), days: round(days * target / ytd))
  end

  defp required_average(_ytd, _now, nil), do: 0

  defp required_average(ytd, now, target) do
    days_left = Timex.diff(Timex.end_of_year(now), now, :days) + 1
    (target - ytd) / days_left * 7
  end
end
