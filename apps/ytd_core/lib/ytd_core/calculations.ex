defmodule YTDCore.Calculations do
  @moduledoc false

  @spec projected_annual(float, %Date{}) :: float
  def projected_annual(miles, date) do
    yday = Timex.day date
    days = if Timex.is_leap?(date), do: 366, else: 365
    miles * days / yday
  end

  @spec weekly_average(float, %Date{}) :: float
  def weekly_average(miles, date) do
    yday = Timex.day date
    miles / yday * 7
  end
end
