defmodule YTDWeb.EventsController do
  @moduledoc """
  Controller for Strava webhook events API.
  """

  use YTDWeb, :controller

  alias Plug.Conn

  @spec validate(Conn.t(), %{String.t() => String.t()}) :: Conn.t()
  def validate(conn, params) do
    json(conn, %{"hub.challenge": params["hub.challenge"]})
  end
end
