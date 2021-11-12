defmodule YTDWeb.EventsController do
  @moduledoc """
  Controller for Strava webhook events API.
  """

  use YTDWeb, :controller

  alias Plug.Conn

  require Logger

  @spec validate(Conn.t(), %{String.t() => String.t()}) :: Conn.t()
  def validate(conn, params) do
    json(conn, %{"hub.challenge": params["hub.challenge"]})
  end

  @spec event(Conn.t(), %{String.t() => String.t()}) :: Conn.t()
  def event(conn, params) do
    Logger.info("Received event: #{inspect(params)}")
    text(conn, "")
  end
end
