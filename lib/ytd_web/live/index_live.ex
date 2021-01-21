defmodule YTDWeb.IndexLive do
  @moduledoc """
  Live view for main index page.
  """

  use YTDWeb, :live_view

  alias Phoenix.PubSub
  alias YTD.Users

  require Logger

  @impl true
  def mount(_params, session, socket) do
    user = Users.get_user_from_athlete_id(session["athlete_id"])

    if connected?(socket) do
      :ok = PubSub.subscribe(:ytd, "user:#{user.id}")
      :ok = PubSub.broadcast!(:ytd, "activities", {:get_activities, user})
    end

    {:ok, assign(socket, user: user, ytd: 0.0, info: "Loading activities …")}
  end

  @impl true
  def handle_info({:existing_activities, activities}, socket) do
    {:noreply,
     assign(socket,
       activities: activities,
       ytd: total_mileage(activities),
       info:
         "#{length(activities)} #{if length(activities) == 1, do: "activity", else: "activities"} loaded. Fetching new activities …"
     )}
  end

  def handle_info({:new_activity, activity}, socket) do
    activities = [activity | socket.assigns.activities]

    {:noreply,
     assign(socket,
       activities: activities,
       ytd: total_mileage(activities),
       info:
         "#{length(activities)} #{if length(activities) == 1, do: "activity", else: "activities"} loaded. Fetching new activities …"
     )}
  end

  def handle_info(:all_activities_fetched, socket) do
    {:noreply, assign(socket, info: nil)}
  end

  defp total_mileage([]), do: 0.0

  defp total_mileage(activities) do
    activities |> Enum.map(& &1.distance) |> Enum.sum() |> metres_to_miles()
  end

  @metres_in_a_mile 1609.34

  defp metres_to_miles(metres) do
    Float.round(metres / @metres_in_a_mile, 1)
  end
end