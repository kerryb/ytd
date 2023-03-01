# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule YTDWeb.IndexLive do
  @moduledoc """
  Live view for main index page.
  """

  use YTDWeb, :live_view
  use YTDWeb, :verified_routes

  import YTDWeb.Components

  alias Phoenix.PubSub
  alias YTD.{Stats, Users, Util}

  require Logger

  @impl true
  def mount(_params, session, socket) do
    user = Users.get_user_from_athlete_id(session["athlete_id"])
    targets = Users.get_targets(user)
    activities = activities_api().get_existing_activities(user)
    type = user.selected_activity_type
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
       refreshing?: true
     )
     |> update_calculated_values()}
  end

  defp fetch_new_activities(user),
    do: Task.start_link(fn -> :ok = activities_api().fetch_activities(user) end)

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

  def handle_event("edit-target", _params, socket),
    do: {:noreply, assign(socket, edit_target?: true)}

  def handle_event("submit-target", %{"target" => target}, socket) do
    Users.save_target(socket.assigns.user, socket.assigns.type, target, socket.assigns.unit)
    targets = Users.get_targets(socket.assigns.user)

    {:noreply,
     socket |> assign(targets: targets, edit_target?: false) |> update_calculated_values()}
  end

  def handle_event("cancel-target", _params, socket),
    do: {:noreply, assign(socket, edit_target?: false)}

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

  def handle_info(:all_activities_fetched, socket),
    do: {:noreply, assign(socket, refreshing?: false)}

  def handle_info({:name_updated, user}, socket), do: {:noreply, assign(socket, user: user)}
  def handle_info(:deauthorised, socket), do: {:noreply, redirect(socket, to: "/")}

  def handle_info(message, socket) do
    Logger.warn("#{__MODULE__} Received unexpected message #{inspect(message)}")
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

  defp types(activities),
    do: activities |> Enum.reject(&(&1.distance == 0)) |> Enum.map(& &1.type) |> Enum.uniq()

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
    |> Enum.reject(&(&1.type != type or DateTime.compare(&1.start_date, start_of_day) == :lt))
    |> sum_of_distances(unit)
  end

  defp month_totals(activities, type, unit),
    do: Enum.map(1..12, &month_total(&1, activities, type, unit))

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

  attr(:activities, :list, required: true)
  attr(:unit, :string, required: true)

  defp day_activities(assigns) do
    total =
      case assigns.activities do
        [] ->
          nil

        activities ->
          activities
          |> Enum.map(&Util.convert(&1.distance, from: "metres", to: assigns.unit))
          |> Enum.sum()
          |> Float.round(1)
      end

    count = length(assigns.activities)
    assigns = assign(assigns, total: total, count: count)

    ~H"""
    <td>
      <%= if @total do %>
        <%= @total %>
        <%= if @count > 1 do %>
          <span class="font-thin">(<%= @count %>)</span>
        <% end %>
      <% end %>
    </td>
    """
  end

  attr(:activities, :list, required: true)
  attr(:type, :string, required: true)
  attr(:unit, :string, required: true)
  attr(:target, :integer, required: true)
  attr(:ytd, :integer, required: true)

  defp graph(assigns) do
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
    Enum.map(
      activities,
      &{Date.day_of_year(&1.start_date), Util.convert(&1.distance, from: "metres", to: unit)}
    )
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
