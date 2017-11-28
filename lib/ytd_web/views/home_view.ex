defmodule YTDWeb.HomeView do
  use YTDWeb, :view

  def format_number(number), do: :io_lib.format "~.1f", [number]

  def format_date(date), do: Timex.format! date, "{D} {Mfull}"
end
