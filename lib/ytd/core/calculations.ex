defmodule YTD.Core.Calculations do
  @moduledoc false

  @spec projected_annual(float, %Date{}) :: float
  def projected_annual(miles, date) do
    miles * days_in_year(date) / Timex.day(date)
  end

  @spec weekly_average(float, %Date{}) :: float
  def weekly_average(miles, date) do
    miles / Timex.day(date) * 7
  end

  def on_target?(miles, date, target), do: projected_annual(miles, date) >= target

  @spec extra_needed_today(float, %Date{}, integer) :: float
  def extra_needed_today(miles, date, target) do
    target * Timex.day(date) / days_in_year(date) - miles
  end

  @spec extra_needed_this_week(float, %Date{}, integer,
                               Timex.Types.weekday) :: float
  def extra_needed_this_week(miles, date, target, week_start) do
    end_of_week = date |> Timex.end_of_week(week_start) |> Timex.day
    target * end_of_week / days_in_year(date) - miles
  end

  defp days_in_year(date), do: if Timex.is_leap?(date), do: 366, else: 365

  def estimated_target_completion(miles, date, target) do
    beginning_of_year = Timex.beginning_of_year(date)
    yday = Timex.diff date, beginning_of_year, :days
    Timex.shift beginning_of_year, days: round(yday * target / miles)
  end
end
