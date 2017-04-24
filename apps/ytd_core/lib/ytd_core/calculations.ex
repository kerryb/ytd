defmodule YTDCore.Calculations do
  @moduledoc false

  @spec projected_annual(float, %Date{}) :: float
  def projected_annual(miles, date) do
    miles * days_in_year(date) / Timex.day(date)
  end

  @spec weekly_average(float, %Date{}) :: float
  def weekly_average(miles, date) do
    miles / Timex.day(date) * 7
  end

  @spec extra_needed_today(float, %Date{}, integer) :: float
  def extra_needed_today(miles, date, target) do
    target * Timex.day(date) / days_in_year(date) - miles
  end

  defp days_in_year(date), do: if Timex.is_leap?(date), do: 366, else: 365
end
