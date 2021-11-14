# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule YTDWeb.IndexLive do
  @moduledoc """
  Live view for main index page.
  """

  use YTDWeb, :live_view

  alias YTD.{Stats, Users, Util}
  alias YTDWeb.Endpoint
  # credo:disable-for-next-line Credo.Check.Readability.AliasAs
  alias YTDWeb.Router.Helpers, as: Routes

  require Logger

  @impl true
  def mount(_params, session, socket) do
    user = Users.get_user_from_athlete_id(session["athlete_id"])
    targets = Users.get_targets(user)

    if connected?(socket) do
      get_activities(user)
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

  defp target_progress(assigns) do
    ~H"""
    <%= cond do %>
      <% @stats.completed? -> %>
        <.target_hit target={@target} />
      <% @stats.on_target? -> %>
        <.on_target target={@target} stats={@stats} unit={@unit} info={@info} />
      <% true -> %>
        <.behind_target target={@target} stats={@stats} unit={@unit} info={@info} />
    <% end %>
    """
  end

  defp target_hit(assigns) do
    ~H"""
    You have hit your target of
    <a class="link" href="#" id="edit-target" phx-click="edit-target">
      <%= @target.target %> <%= @target.unit %></a>!
    """
  end

  defp on_target(assigns) do
    ~H"""
    You are on track to hit your target of
    <a class="link" href="#" id="edit-target" phx-click="edit-target">
      <%= @target.target %> <%= @target.unit %></a>, as long as you average
    <span class={pulse_if_loading("font-extrabold", @info)}><%= @stats.required_average %> <%= @unit %></span>
    a week from now on.
    """
  end

  defp behind_target(assigns) do
    ~H"""
    To hit your target of
    <a class="link" href="#" id="edit-target" phx-click="edit-target">
      <%= @target.target %> <%= @target.unit %></a>, you need to average
    <span class={pulse_if_loading("font-extrabold", @info)}><%= @stats.required_average %> <%= @unit %></span>
    a week from now on.
    """
  end

  defp edit_target_modal(assigns) do
    ~H"""
    <div class="p-4 fixed flex justify-center items-center inset-0 bg-black bg-opacity-75 z-50">
      <div class="max-w-xl max-h-full bg-strava-orange rounded shadow-lg overflow-auto p-4 mb-2">
        <form id="edit-target-form" phx-submit="submit-target">
          <div class="mb-4">
            <label for="target"><%= @type %> target: </label>
            <input autofocus="true" class="w-20 text-strava-orange pl-2 ml-2 rounded" id="target" name="target" type="number" value={if @target, do: @target.target, else: 0}>
            <%= @unit %>
          </div>
          <div class="flex justify-between">
            <button class="font-thin border rounded px-1 bg-strava-orange hover:bg-strava-orange-dark" phx-click="cancel-target" type="button">Cancel</button>
            <button class="font-bold border-2 rounded px-1 bg-white text-strava-orange hover:bg-gray-200" type="submit">Save</button>
          </div>
        </form>
      </div>
    </div>
    """
  end

  defp pulse_if_loading(class, nil), do: class
  defp pulse_if_loading(class, _info), do: "#{class} animate-pulse"

  defp get_activities(user) do
    pid = self()
    Task.start_link(fn -> :ok = activities_api().fetch_activities(pid, user) end)
  end

  defp update_name(user) do
    pid = self()
    Task.start_link(fn -> :ok = users_api().update_name(pid, user) end)
  end

  @impl true
  def handle_params(%{"activity_type" => type}, _uri, socket) do
    ytd = total_distance(socket.assigns.activities, type, socket.assigns.unit)
    count = activity_count(socket.assigns.activities, type)

    stats =
      calculate_stats(ytd, socket.assigns.unit, Date.utc_today(), type, socket.assigns.targets)

    latest = latest_activity_of_type(socket.assigns.activities, type)
    Users.save_activity_type(socket.assigns.user, type)
    {:noreply, assign(socket, type: type, ytd: ytd, count: count, stats: stats, latest: latest)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("select", %{"_target" => ["type"], "type" => type}, socket) do
    {:noreply, push_patch(socket, to: Routes.index_path(Endpoint, :index, type))}
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

    pid = self()
    Task.start_link(fn -> :ok = activities_api().reload_activities(pid, socket.assigns.user) end)

    {:noreply,
     assign(socket,
       activities: [],
       latest: nil,
       count: count,
       ytd: ytd,
       stats: stats,
       info: "Reloading all activities …"
     )}
  end

  def handle_event("refresh", _params, socket) do
    pid = self()
    Task.start_link(fn -> :ok = activities_api().refresh_activities(pid, socket.assigns.user) end)
    {:noreply, assign(socket, info: "Refreshing activities …")}
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
    latest = latest_activity_of_type(activities, socket.assigns.type)
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
       latest: latest,
       count: count,
       types: types,
       ytd: ytd,
       stats: stats,
       info: info
     )}
  end

  def handle_info({:new_activity, activity}, socket) do
    activities = [activity | socket.assigns.activities]
    latest = latest_activity_of_type(activities, socket.assigns.type)
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
       latest: latest,
       count: count,
       types: types,
       ytd: ytd,
       stats: stats,
       info: info
     )}
  end

  def handle_info(:all_activities_fetched, socket) do
    latest = latest_activity_of_type(socket.assigns.activities, socket.assigns.type)
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
    activities |> Enum.reject(&(&1.distance == 0)) |> Enum.map(& &1.type) |> Enum.uniq()
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

  defp activities_api, do: Application.fetch_env!(:ytd, :activities_api)
  defp users_api, do: Application.fetch_env!(:ytd, :users_api)
end
