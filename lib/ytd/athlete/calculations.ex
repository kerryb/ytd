defmodule YTD.Athlete.Calculations do
  @moduledoc """
  Perform various calculations based on the current date and actual and total
  mileage.
  """

  @doc """
  Given the current mileage and today's date, return the projected annual
  mileage.
  """
  @spec projected_annual(float, %Date{}) :: float
  def projected_annual(miles, date) do
    miles * days_in_year(date) / Timex.day(date)
  end

  defp days_in_year(date), do: if Timex.is_leap?(date), do: 366, else: 365

  @doc """
  Given the current mileage and today's date, return the average weekly mileage
  so far this year.
  """
  @spec weekly_average(float, %Date{}) :: float
  def weekly_average(miles, date) do
    miles / Timex.day(date) * 7
  end

  @doc """
  Given the current mileage, today's date and target, indicate whether the
  athlete is on track for their target.
  """
  @spec on_target?(float, %Date{}, integer) :: boolean
  def on_target?(miles, date, target), do: projected_annual(miles, date) >= target

  @doc """
  Given the current mileage, today's date and target, return the projected date
  on which the target will be met.
  """
  @spec estimated_target_completion(float, %Date{}, integer) :: %Date{}
  def estimated_target_completion(miles, date, target) do
    days = Timex.day(date) - 1
    Timex.shift(Timex.beginning_of_year(date),
                days: round(days * target / miles))
  end

  @doc """
  Given the current mileage, today's date and target, return the average weekly
  milage required from this point onwards to reach the target.
  """
  @spec required_average(float, %Date{}, integer) :: float
  def required_average(miles, date, target) do
    days_left = Timex.diff(Timex.end_of_year(date), date, :days) + 1
    (target - miles) / days_left * 7
  end
end
