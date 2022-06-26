defmodule YTDWeb.EventsController do
  @moduledoc """
  Controller for Strava webhook events API.
  """

  use YTDWeb, :controller

  alias Plug.Conn

  require Logger

  @spec validate(Conn.t(), %{String.t() => String.t()}) :: Conn.t()
  def validate(conn, params), do: json(conn, %{"hub.challenge": params["hub.challenge"]})

  @spec event(Conn.t(), %{String.t() => String.t()}) :: Conn.t()
  def event(conn, event) do
    Logger.info("Received webhook event #{inspect(event)}")
    handle_event(event)
    text(conn, "")
  end

  defp handle_event(%{
         "aspect_type" => operation,
         "object_id" => id,
         "object_type" => type,
         "owner_id" => athlete_id,
         "updates" => updates
       }) do
    case {type, operation} do
      {"activity", "create"} -> activities_api().activity_created(athlete_id, id)
      {"activity", "update"} -> activities_api().activity_updated(athlete_id, id)
      {"activity", "delete"} -> activities_api().activity_deleted(athlete_id, id)
      {"athlete", "update"} -> users_api().athlete_updated(athlete_id, updates)
      {"athlete", "delete"} -> users_api().athlete_deleted(athlete_id)
      _params -> :ok
    end
  end

  defp activities_api, do: Application.fetch_env!(:ytd, :activities_api)
  defp users_api, do: Application.fetch_env!(:ytd, :users_api)
end
