# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule YTDWeb.IndexLive do
  @moduledoc """
  Live view for main index page.
  """

  use YTDWeb, :live_view

  alias Phoenix.PubSub
  alias YTD.{Stats, Users, Util}
  alias YTDWeb.Endpoint
  # credo:disable-for-next-line Credo.Check.Readability.AliasAs
  alias YTDWeb.Router.Helpers, as: Routes

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

  defp target_progress(assigns) do
    ~H"""
    <%= cond do %>
      <% @stats.completed? -> %>
        <.target_hit target={@target} />
      <% @stats.on_target? -> %>
        <.on_target target={@target} stats={@stats} unit={@unit} />
      <% true -> %>
        <.behind_target target={@target} stats={@stats} unit={@unit} />
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
    <span class="font-extrabold"><%= @stats.required_average %> <%= @unit %></span>
    a week from now on.
    """
  end

  defp behind_target(assigns) do
    ~H"""
    To hit your target of
    <a class="link" href="#" id="edit-target" phx-click="edit-target">
      <%= @target.target %> <%= @target.unit %></a>, you need to average
    <span class="font-extrabold"><%= @stats.required_average %> <%= @unit %></span>
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

  defp fetch_new_activities(user) do
    Task.start_link(fn -> :ok = activities_api().fetch_activities(user) end)
  end

  defp update_name(user) do
    Task.start_link(fn -> :ok = users_api().update_name(user) end)
  end

  @impl true
  def handle_params(%{"activity_type" => type}, _uri, socket) do
    Users.save_activity_type(socket.assigns.user, type)
    {:noreply, socket |> assign(type: type) |> update_calculated_values()}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("select", %{"_target" => ["type"], "type" => type}, socket) do
    {:noreply, push_patch(socket, to: Routes.index_path(Endpoint, :index, type))}
  end

  def handle_event("select", %{"_target" => ["unit"], "unit" => unit}, socket) do
    {:noreply, socket |> assign(unit: unit) |> update_calculated_values()}
  end

  def handle_event("refresh", %{"shift_key" => true}, socket) do
    Task.start_link(fn -> :ok = activities_api().reload_activities(socket.assigns.user) end)
    {:noreply, socket |> assign(activities: [], refreshing?: true) |> update_calculated_values()}
  end

  def handle_event("refresh", _params, socket) do
    Task.start_link(fn -> :ok = activities_api().refresh_activities(socket.assigns.user) end)
    {:noreply, assign(socket, refreshing?: true)}
  end

  def handle_event("edit-target", _params, socket) do
    {:noreply, assign(socket, edit_target?: true)}
  end

  def handle_event("submit-target", %{"target" => target}, socket) do
    Users.save_target(socket.assigns.user, socket.assigns.type, target, socket.assigns.unit)
    targets = Users.get_targets(socket.assigns.user)

    {:noreply,
     socket |> assign(targets: targets, edit_target?: false) |> update_calculated_values()}
  end

  def handle_event("cancel-target", _params, socket) do
    {:noreply, assign(socket, edit_target?: false)}
  end

  def handle_info({:new_activity, activity}, socket) do
    activities = [activity | socket.assigns.activities]
    {:noreply, socket |> assign(activities: activities) |> update_calculated_values()}
  end

  @impl true
  def handle_info(:all_activities_fetched, socket) do
    latest = latest_activity_of_type(socket.assigns.activities, socket.assigns.type)
    {:noreply, assign(socket, latest: latest, refreshing?: false)}
  end

  def handle_info({:name_updated, user}, socket) do
    {:noreply, assign(socket, user: user)}
  end

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
    latest = latest_activity_of_type(activities, type)
    ytd = total_distance(activities, type, unit)
    stats = calculate_stats(ytd, unit, Date.utc_today(), type, targets)

    assign(socket,
      count: count,
      types: types,
      latest: latest,
      stats: stats,
      ytd: ytd
    )
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
