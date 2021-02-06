defmodule YTDWeb.IndexLive do
  @moduledoc """
  Live view for main index page.
  """

  use YTDWeb, :live_view

  alias Phoenix.PubSub
  alias YTD.{Stats, Users}

  require Logger

  @impl true
  def mount(_params, session, socket) do
    user = Users.get_user_from_athlete_id(session["athlete_id"])

    if connected?(socket) do
      :ok = PubSub.subscribe(:ytd, "user:#{user.id}")
      :ok = PubSub.broadcast!(:ytd, "activities", {:get_activities, user})
    end

    {:ok,
     assign(socket,
       user: user,
       activities: [],
       types: [user.selected_activity_type],
       type: user.selected_activity_type,
       unit: user.selected_unit,
       ytd: 0.0,
       stats: Stats.calculate(0.0, Date.utc_today()),
       info: "Loading activities …",
       latest: nil
     )}
  end

  @impl true
  def handle_event("select", %{"_target" => ["type"], "type" => type}, socket) do
    ytd = total_distance(socket.assigns.activities, type, socket.assigns.unit)
    stats = Stats.calculate(ytd, Date.utc_today())
    latest = latest_activity(socket.assigns.activities, type)
    PubSub.broadcast!(:ytd, "users", {:activity_type_changed, socket.assigns.user, type})
    {:noreply, assign(socket, type: type, ytd: ytd, stats: stats, latest: latest)}
  end

  def handle_event("select", %{"_target" => ["unit"], "unit" => unit}, socket) do
    ytd = total_distance(socket.assigns.activities, socket.assigns.type, unit)
    stats = Stats.calculate(ytd, Date.utc_today())
    PubSub.broadcast!(:ytd, "users", {:unit_changed, socket.assigns.user, unit})
    {:noreply, assign(socket, unit: unit, ytd: ytd, stats: stats)}
  end

  @impl true
  def handle_info({:existing_activities, activities}, socket) do
    ytd = total_distance(activities, socket.assigns.type, socket.assigns.unit)
    stats = Stats.calculate(ytd, Date.utc_today())
    types = types(activities)
    info = fetching_message(activities)

    {:noreply,
     assign(socket, activities: activities, types: types, ytd: ytd, stats: stats, info: info)}
  end

  def handle_info({:new_activity, activity}, socket) do
    activities = [activity | socket.assigns.activities]
    ytd = total_distance(activities, socket.assigns.type, socket.assigns.unit)
    stats = Stats.calculate(ytd, Date.utc_today())
    types = types(activities)
    info = fetching_message(activities)

    {:noreply,
     assign(socket, activities: activities, types: types, ytd: ytd, stats: stats, info: info)}
  end

  def handle_info(:all_activities_fetched, socket) do
    latest = latest_activity(socket.assigns.activities, socket.assigns.type)
    {:noreply, assign(socket, info: nil, latest: latest)}
  end

  defp types(activities) do
    activities |> Enum.map(& &1.type) |> Enum.uniq()
  end

  defp total_distance([], _type, _unit), do: 0.0

  defp total_distance(activities, type, unit) do
    activities
    |> Enum.filter(&(&1.type == type))
    |> Enum.map(& &1.distance)
    |> Enum.sum()
    |> metres_to_unit(unit)
  end

  defp fetching_message([_activity]), do: fetching_message(1, "activity")
  defp fetching_message(activities), do: fetching_message(length(activities), "activities")
  defp fetching_message(count, noun), do: "#{count} #{noun} loaded. Fetching new activities …"

  defp latest_activity([], _type), do: nil

  defp latest_activity(activities, type) do
    activities
    |> Enum.filter(&(&1.type == type))
    |> Enum.max_by(& &1.start_date, DateTime)
  end

  defp metres_to_unit(metres, "miles"), do: Float.round(metres / 1609.34, 1)
  defp metres_to_unit(metres, "km"), do: Float.round(metres / 1000, 1)
end
