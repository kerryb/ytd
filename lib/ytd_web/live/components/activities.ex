defmodule YTDWeb.Components.Activities do
  @moduledoc """
  Component functions for the activities tab.
  """

  use Phoenix.Component

  alias YTD.Util

  attr(:activities, :list, required: true)
  attr(:week_beginning, Date, required: true)
  attr(:day, :integer, required: true)
  attr :selected, :boolean, required: true
  attr(:unit, :string, required: true)

  def day_activities(%{activities: []} = assigns) do
    ~H"""
    <td class="border-r dark:border-strava-orange"></td>
    """
  end

  def day_activities(%{activities: activities} = assigns) do
    total =
      activities
      |> Enum.map(&Util.convert(&1.distance, from: "metres", to: assigns.unit))
      |> Enum.sum()
      |> Float.round(1)

    count = length(activities)
    assigns = assign(assigns, total: total, count: count)

    ~H"""
    <td class={"border-r dark:border-strava-orange #{if @selected, do: "bg-white dark:bg-strava-orange text-strava-orange dark:text-black"}"}>
      <a
        class="link"
        href="#"
        phx-click="show-activities"
        phx-click-away="hide-activities"
        phx-value-week-beginning={@week_beginning}
        phx-value-day={@day}
      >
        {@total}
      </a>
      <%= if @count > 1 do %>
        <span class="font-thin">⧉</span>
      <% end %>
    </td>
    """
  end
end
