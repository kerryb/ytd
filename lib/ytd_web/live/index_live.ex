# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule YTDWeb.IndexLive do
  @moduledoc """
  Live view for main index page.
  """

  use YTDWeb, :live_view

  alias Phoenix.PubSub
  alias YTD.{Stats, Users, Util}

  require Logger

  @impl true
  def mount(_params, session, socket) do
    user = Users.get_user_from_athlete_id(session["athlete_id"])
    targets = Users.get_targets(user)

    if connected?(socket) do
      :ok = PubSub.subscribe(:ytd, "user:#{user.id}")
      get_activities(self(), user)
      update_name(user)
    end

    {:ok,
     assign(socket,
       user: user,
       activities: [],
       targets: targets,
       count: activity_count([], user.selected_activity_type),
       types: [user.selected_activity_type],
       type: user.selected_activity_type,
       unit: user.selected_unit,
       ytd: 0.0,
       stats:
         calculate_stats(
           0.0,
           user.selected_unit,
           Date.utc_today(),
           user.selected_activity_type,
           targets
         ),
       info: "Loading activities …",
       latest: nil,
       edit_target?: false
     )}
  end

  defp get_activities(pid, user) do
    Task.start_link(fn -> :ok = activities_api().fetch_activities(pid, user) end)
  end

  defp update_name(user) do
    Task.start_link(fn -> :ok = PubSub.broadcast!(:ytd, "users", {:update_name, user}) end)
  end

  @impl true
  def handle_event("select", %{"_target" => ["type"], "type" => type}, socket) do
    ytd = total_distance(socket.assigns.activities, type, socket.assigns.unit)
    count = activity_count(socket.assigns.activities, type)

    stats =
      calculate_stats(ytd, socket.assigns.unit, Date.utc_today(), type, socket.assigns.targets)

    latest = latest_activity(socket.assigns.activities, type)
    Users.save_activity_type(socket.assigns.user, type)
    {:noreply, assign(socket, type: type, ytd: ytd, count: count, stats: stats, latest: latest)}
  end

  def handle_event("select", %{"_target" => ["unit"], "unit" => unit}, socket) do
    ytd = total_distance(socket.assigns.activities, socket.assigns.type, unit)

    stats =
      calculate_stats(ytd, unit, Date.utc_today(), socket.assigns.type, socket.assigns.targets)

    {:noreply, assign(socket, unit: unit, ytd: ytd, stats: stats)}
  end

  def handle_event("refresh", %{"shift_key" => true}, socket) do
    count = activity_count([], socket.assigns.type)
    ytd = 0.0

    stats =
      calculate_stats(
        0.0,
        socket.assigns.unit,
        Date.utc_today(),
        socket.assigns.type,
        socket.assigns.targets
      )

    PubSub.broadcast!(:ytd, "activities", {:reset_activities, socket.assigns.user})

    {:noreply,
     assign(socket,
       activities: [],
       latest: nil,
       count: count,
       ytd: ytd,
       stats: stats,
       info: "Re-fetching all activities …"
     )}
  end

  def handle_event("refresh", _params, socket) do
    pid = self()
    Task.start_link(fn -> :ok = activities_api().refresh_activities(pid, socket.assigns.user) end)
    {:noreply, assign(socket, latest: nil, info: "Refreshing activities …")}
  end

  def handle_event("edit-target", _params, socket) do
    {:noreply, assign(socket, edit_target?: true)}
  end

  def handle_event("submit-target", %{"target" => target}, socket) do
    Users.save_target(socket.assigns.user, socket.assigns.type, target, socket.assigns.unit)
    targets = Users.get_targets(socket.assigns.user)

    stats =
      calculate_stats(
        socket.assigns.ytd,
        socket.assigns.unit,
        Date.utc_today(),
        socket.assigns.type,
        targets
      )

    {:noreply, assign(socket, targets: targets, stats: stats, edit_target?: false)}
  end

  def handle_event("cancel-target", _params, socket) do
    {:noreply, assign(socket, edit_target?: false)}
  end

  @impl true
  def handle_info({:existing_activities, activities}, socket) do
    count = activity_count(activities, socket.assigns.type)
    ytd = total_distance(activities, socket.assigns.type, socket.assigns.unit)

    stats =
      calculate_stats(
        ytd,
        socket.assigns.unit,
        Date.utc_today(),
        socket.assigns.type,
        socket.assigns.targets
      )

    types = types(activities)
    info = fetching_message(activities)

    {:noreply,
     assign(socket,
       activities: activities,
       count: count,
       types: types,
       ytd: ytd,
       stats: stats,
       info: info
     )}
  end

  def handle_info({:new_activity, activity}, socket) do
    activities = [activity | socket.assigns.activities]
    count = activity_count(activities, socket.assigns.type)
    ytd = total_distance(activities, socket.assigns.type, socket.assigns.unit)

    stats =
      calculate_stats(
        ytd,
        socket.assigns.unit,
        Date.utc_today(),
        socket.assigns.type,
        socket.assigns.targets
      )

    types = types(activities)
    info = fetching_message(activities)

    {:noreply,
     assign(socket,
       activities: activities,
       count: count,
       types: types,
       ytd: ytd,
       stats: stats,
       info: info
     )}
  end

  def handle_info(:all_activities_fetched, socket) do
    latest = latest_activity(socket.assigns.activities, socket.assigns.type)
    {:noreply, assign(socket, info: nil, latest: latest)}
  end

  def handle_info({:name_updated, user}, socket) do
    {:noreply, assign(socket, user: user)}
  end

  def handle_info(message, socket) do
    Logger.warn("#{__MODULE__} Received unexpected message #{inspect(message)}")
    {:noreply, socket}
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
    |> Util.convert(from: "metres", to: unit)
    |> Float.round(1)
  end

  defp activity_count(activities, type) do
    activities
    |> Enum.count(&(&1.type == type))
    |> case do
      1 -> "1 activity"
      count -> "#{count} activities"
    end
  end

  defp fetching_message([_activity]), do: fetching_message(1, "activity")
  defp fetching_message(activities), do: fetching_message(length(activities), "activities")

  defp fetching_message(count, noun),
    do: "#{count} #{noun} loaded. Fetching new activities …"

  defp latest_activity([], _type), do: nil

  defp latest_activity(activities, type) do
    activities
    |> Enum.filter(&(&1.type == type))
    |> Enum.max_by(& &1.start_date, DateTime)
  end

  defp calculate_stats(ytd, unit, date, activity_type, targets) do
    target =
      case targets[activity_type] do
        nil -> nil
        target -> Util.convert(target.target, from: target.unit, to: unit)
      end

    Stats.calculate(ytd, date, target)
  end

  defp activities_api, do: Application.fetch_env!(:ytd, :activities_api)
end
