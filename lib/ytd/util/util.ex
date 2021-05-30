defmodule YTD.Util do
  @moduledoc """
  Utility functions for unit conversion etc
  """

  use Boundary, top_level?: true, deps: []

  @spec convert(float(), [{:from, String.t()}, {:to, String.t()}]) :: float()
  def convert(distance, from: unit, to: unit), do: distance
  def convert(distance, from: "km", to: "miles"), do: distance / 1.609344
  def convert(distance, from: "miles", to: "km"), do: distance * 1.609344
  def convert(distance, from: "metres", to: "miles"), do: distance / 1609.344
  def convert(distance, from: "metres", to: "km"), do: distance / 1000
end
