# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule YTDWeb.IndexLive do
  @moduledoc """
  Live view for main index page.
  """

  use YTDWeb, :live_view
  use YTDWeb, :verified_routes

  import YTDWeb.Components.Activities
  import YTDWeb.Components.Graph
  import YTDWeb.Components.Summary

  alias Phoenix.PubSub
  alias YTD.Stats
  alias YTD.Users
  alias YTD.Util

  require Logger

  @impl true
  def mount(_params, session, socket) do
    user = Users.get_user_from_athlete_id(session["athlete_id"])
    targets = Users.get_targets(user)
    activities = activities_api().get_existing_activities(user)
    type = saved_or_latest_activity_type(user, activities)
    unit = user.selected_unit

    if connected?(socket) do
      PubSub.subscribe(:ytd, "athlete:#{user.athlete_id}")
      fetch_new_activities(user)
      update_name(user)
    end

    {:ok,
     socket
     |> assign(
       tab: "summary",
       user: user,
       activities: activities,
       targets: targets,
       type: type,
       unit: unit,
       edit_target?: false,
       week_beginning: nil,
       day: nil,
       refreshing?: true
     )
     |> update_calculated_values()}
  end

  def saved_or_latest_activity_type(user, activities) do
    saved_type = user.selected_activity_type

    if activities == [] or Enum.any?(activities, &(&1.type == saved_type)) do
      saved_type
    else
      latest_activity(activities).type
    end
  end

  defp fetch_new_activities(user), do: Task.start_link(fn -> :ok = activities_api().fetch_activities(user) end)

  defp update_name(user), do: Task.start_link(fn -> :ok = users_api().update_name(user) end)

  @impl true
  def handle_params(%{"activity_type" => type, "tab" => tab}, _uri, socket) do
    {:noreply, socket |> assign(tab: tab) |> set_type(type) |> update_calculated_values()}
  end

  def handle_params(%{"activity_type" => type}, _uri, socket) do
    {:noreply, socket |> set_type(type) |> update_calculated_values()}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  defp set_type(socket, nil), do: socket

  defp set_type(socket, type) do
    Users.save_activity_type(socket.assigns.user, type)
    assign(socket, type: type)
  end

  @impl true
  def handle_event("select", %{"_target" => ["type"], "type" => type}, socket),
    do: {:noreply, push_patch(socket, to: ~p"/#{type}/#{socket.assigns.tab}")}

  def handle_event("select", %{"_target" => ["unit"], "unit" => unit}, socket),
    do: {:noreply, socket |> assign(unit: unit) |> update_calculated_values()}

  def handle_event("refresh", _params, socket) do
    Task.start_link(fn -> :ok = activities_api().reload_activities(socket.assigns.user) end)
    {:noreply, socket |> assign(activities: [], refreshing?: true) |> update_calculated_values()}
  end

  def handle_event("edit-target", _params, socket), do: {:noreply, assign(socket, edit_target?: true)}

  def handle_event("submit-target", %{"target" => target}, socket) do
    Users.save_target(socket.assigns.user, socket.assigns.type, target, socket.assigns.unit)
    targets = Users.get_targets(socket.assigns.user)

    {:noreply, socket |> assign(targets: targets, edit_target?: false) |> update_calculated_values()}
  end

  def handle_event("cancel-target", _params, socket), do: {:noreply, assign(socket, edit_target?: false)}

  def handle_event("show-activities", params, socket) do
    {:noreply,
     assign(socket,
       week_beginning: params["week-beginning"] |> Timex.parse!("{YYYY}-{M}-{D}") |> Timex.to_date(),
       day: String.to_integer(params["day"])
     )}
  end

  def handle_event("hide-activities", _params, socket), do: {:noreply, assign(socket, week_beginning: nil, day: nil)}

  @impl true
  def handle_info({:new_activity, activity}, socket) do
    activities = [activity | socket.assigns.activities]
    {:noreply, socket |> assign(activities: activities) |> update_calculated_values()}
  end

  def handle_info({:updated_activity, %{strava_id: strava_id} = activity}, socket) do
    activities =
      Enum.map(
        socket.assigns.activities,
        fn
          %{strava_id: ^strava_id} -> activity
          other -> other
        end
      )

    {:noreply, socket |> assign(activities: activities) |> update_calculated_values()}
  end

  def handle_info({:deleted_activity, strava_id}, socket) do
    activities = Enum.reject(socket.assigns.activities, &(&1.strava_id == strava_id))
    {:noreply, socket |> assign(activities: activities) |> update_calculated_values()}
  end

  def handle_info(:all_activities_fetched, socket), do: {:noreply, assign(socket, refreshing?: false)}

  def handle_info({:name_updated, user}, socket), do: {:noreply, assign(socket, user: user)}
  def handle_info(:deauthorised, socket), do: {:noreply, redirect(socket, to: "/")}

  def handle_info(message, socket) do
    Logger.warning("#{__MODULE__} Received unexpected message #{inspect(message)}")
    {:noreply, socket}
  end

  defp update_calculated_values(socket) do
    activities = socket.assigns.activities
    type = socket.assigns.type
    unit = socket.assigns.unit
    targets = socket.assigns.targets

    count = activity_count(activities, type)
    types = types(activities)
    latest_activity = latest_activity_of_type(activities, type)
    latest_activity_name = if(latest_activity, do: latest_activity.name)

    latest_activity_time =
      if(latest_activity, do: Timex.format!(latest_activity.start_date, "{relative}", :relative))

    ytd = total_distance(activities, type, unit)
    stats = calculate_stats(ytd, unit, Date.utc_today(), type, targets)
    copy_text = "#{today_distance(activities, type, unit)}/#{ytd}"

    month_totals = month_totals(activities, type, unit)
    activities_by_week = activities_by_week(activities, type)

    assign(socket,
      count: count,
      types: types,
      latest_activity_name: latest_activity_name,
      latest_activity_time: latest_activity_time,
      stats: stats,
      ytd: ytd,
      copy_text: copy_text,
      month_totals: month_totals,
      activities_by_week: activities_by_week
    )
  end

  defp types(activities), do: activities |> Enum.reject(&(&1.distance == 0)) |> Enum.map(& &1.type) |> Enum.uniq()

  defp total_distance([], _type, _unit), do: 0.0

  defp total_distance(activities, type, unit) do
    activities
    |> Enum.filter(&(&1.type == type))
    |> sum_of_distances(unit)
  end

  defp activity_count(activities, type) do
    activities
    |> Enum.count(&(&1.type == type))
    |> case do
      1 -> "1 activity"
      count -> "#{count} activities"
    end
  end

  defp latest_activity_of_type(activities, type) do
    activities
    |> Enum.filter(&(&1.type == type))
    |> latest_activity()
  end

  defp latest_activity([]), do: nil
  defp latest_activity(activities), do: Enum.max_by(activities, & &1.start_date, DateTime)

  defp calculate_stats(ytd, unit, date, activity_type, targets) do
    target =
      case targets[activity_type] do
        nil -> nil
        target -> Util.convert(target.target, from: target.unit, to: unit)
      end

    Stats.calculate(ytd, date, target)
  end

  defp today_distance(activities, type, unit) do
    start_of_day = Timex.beginning_of_day(DateTime.utc_now())

    activities
    |> Enum.reject(&(&1.type != type or DateTime.before?(&1.start_date, start_of_day)))
    |> sum_of_distances(unit)
  end

  defp month_totals(activities, type, unit), do: Enum.map(1..12, &month_total(&1, activities, type, unit))

  defp month_total(month, activities, type, unit) do
    {Timex.month_name(month),
     activities
     |> Enum.filter(&(&1.type == type and &1.start_date.month == month))
     |> sum_of_distances(unit)}
  end

  defp sum_of_distances(activities, unit) do
    activities
    |> Enum.map(& &1.distance)
    |> Enum.sum()
    |> Util.convert(from: "metres", to: unit)
    |> Float.round(1)
  end

  defp activities_by_week(activities, type) do
    activities |> Enum.filter(&(&1.type == type)) |> activities_api().by_week_and_day()
  end

  defp activities_api, do: Application.fetch_env!(:ytd, :activities_api)
  defp users_api, do: Application.fetch_env!(:ytd, :users_api)

  defp week_label(week_group) do
    if week_group.from.month == week_group.to.month do
      "#{Timex.format!(week_group.from, "{D}")} – #{Timex.format!(week_group.to, "{D} {Mshort}")}"
    else
      "#{Timex.format!(week_group.from, "{D} {Mshort}")} – #{Timex.format!(week_group.to, "{D} {Mshort}")}"
    end
  end
end
