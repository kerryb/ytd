defmodule YTDCore.Calculations do
  @moduledoc false

  @spec projected_annual(float, %Date{}) :: float
  def projected_annual(miles, date) do
    yday = Timex.day date
    miles * days_in_year(date) / yday
  end

  @spec weekly_average(float, %Date{}) :: float
  def weekly_average(miles, date) do
    yday = Timex.day date
    miles / yday * 7
  end

  @spec extra_needed_today(float, %Date{}, integer) :: float
  def extra_needed_today(miles, date, target) do
    yday = Timex.day date
    target * yday / days_in_year(date) - miles
  end

  defp days_in_year(date), do: if Timex.is_leap?(date), do: 366, else: 365
end
