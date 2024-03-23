# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule YTDWeb.Components.Graph do
  @moduledoc """
  Component functions for the summary tab.
  """

  use Phoenix.Component

  alias YTD.Util

  attr(:activities, :list, required: true)
  attr(:type, :string, required: true)
  attr(:unit, :string, required: true)
  attr(:target, :integer, required: true)
  attr(:ytd, :integer, required: true)

  def graph(assigns) do
    activities = Enum.filter(assigns.activities, &(&1.type == assigns.type))
    max_x = max_x()
    max_y = max_y(assigns[:target], assigns.ytd, assigns.unit)
    y_grid_gap = y_grid_gap(max_y)
    horizontal_grid = max_y..0//-y_grid_gap
    vertical_scale_factor = Enum.max([round(max_y / 500), 1])

    vertical_grid =
      Enum.map(1..12, fn month ->
        Date.utc_today() |> Timex.set(month: month, day: 1) |> Date.day_of_year()
      end)

    points =
      activities
      |> days_and_distances(assigns.unit)
      |> make_distances_cumulative()
      |> convert_to_coordinates(max_y)
      |> make_path()

    assigns =
      assign(assigns, %{
        max_x: max_x,
        max_y: max_y,
        y_grid_gap: y_grid_gap,
        horizontal_grid: horizontal_grid,
        vertical_grid: vertical_grid,
        vertical_scale_factor: vertical_scale_factor,
        months: ~w[J F M A M J J A S O N D],
        points: points
      })

    ~H"""
    <svg
      version="1.1"
      class="w-full h-[500px] p-4 stroke-current stroke-1 text-[30px]"
      viewBox="0 0 1000 1000"
      preserveAspectRatio="none"
    >
      <g class="labels x-labels">
        <%= for {name, number} <- Enum.with_index(@months) do %>
          <text x={number * 900 / 12 + 130} y="990"><%= name %></text>
        <% end %>
      </g>
      <g class="labels y-labels">
        <%= for miles <- 0..@max_y//@y_grid_gap  do %>
          <text x="70" y={(@max_y - miles) * 920 / @max_y + 35}><%= miles %></text>
        <% end %>
      </g>
      <svg
        x="100"
        y="20"
        width="900"
        height="930"
        viewBox={"0 0 #{@max_x} #{@max_y}"}
        preserveAspectRatio="none"
      >
        <g class={"grid stroke-[#{@vertical_scale_factor}px]"}>
          <%= for y <- @horizontal_grid do %>
            <line x1="0" x2={@max_x} y1={y} y2={y}></line>
          <% end %>
        </g>
        <g
          class="grid"
          style={"stroke-dasharray: #{@vertical_scale_factor} #{@vertical_scale_factor * 2}"}
        >
          <%= for x <- @vertical_grid do %>
            <line x1={x} x2={x} y1="0" y2={@max_y}></line>
          <% end %>
          <line x1={@max_x} x2={@max_x} y1="0" y2={@max_y}></line>
        </g>
        <%= if @target do %>
          <line id="target" x1="0" x2={@max_x} y1={@max_y} y2="0" />
        <% end %>
        <path id="actual" d={@points} />
      </svg>
    </svg>
    """
  end

  defp max_x, do: Date.utc_today() |> Timex.end_of_year() |> Date.day_of_year()
  defp max_y(nil, ytd, _unit), do: ceil(ytd)

  defp max_y(target, ytd, unit),
    do: [Util.convert(target.target, from: target.unit, to: unit), ytd] |> Enum.max() |> ceil()

  defp y_grid_gap(max_y) when max_y < 250, do: 10
  defp y_grid_gap(max_y) when max_y < 1000, do: 50
  defp y_grid_gap(max_y) when max_y < 2500, do: 100
  defp y_grid_gap(max_y) when max_y < 10_000, do: 500
  defp y_grid_gap(_max_y), do: 1000

  defp days_and_distances(activities, unit) do
    activities_by_date = Enum.group_by(activities, &DateTime.to_date(&1.start_date))

    Enum.map(
      Date.range(Timex.beginning_of_year(Date.utc_today()), Date.utc_today()),
      &{Date.day_of_year(&1), total_distance(Map.get(activities_by_date, &1, []), unit)}
    )
  end

  defp total_distance(activities, unit) do
    activities |> Enum.map(& &1.distance) |> Enum.sum() |> Util.convert(from: "metres", to: unit)
  end

  defp make_distances_cumulative(days_and_distances) do
    days_and_distances
    |> Enum.reduce({[], 0}, fn {day, distance}, {values, total} ->
      {[{day, distance + total} | values], distance + total}
    end)
    |> elem(0)
  end

  defp convert_to_coordinates(days_and_cumulative_distances, max_y) do
    Enum.map(days_and_cumulative_distances, fn {day, total} -> {day, max_y - round(total)} end)
  end

  defp make_path([]), do: ""
  defp make_path([head | tail]), do: Enum.join([move(head) | Enum.map(tail, &draw/1)], " ")
  defp move({x, y}), do: "M #{x},#{y}"
  defp draw({x, y}), do: "L #{x},#{y}"
end
