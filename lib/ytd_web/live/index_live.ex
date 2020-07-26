defmodule YtdWeb.IndexLive do
  @moduledoc """
  Live view for main index page."
  """

  use YtdWeb, :live_view

  @impl true
  def mount(params, session, socket) do
    IO.inspect(params, label: "params")
    IO.inspect(session, label: "session")

    if connected?(socket) do
      if params["code"] do
        client = Strava.Auth.get_token!(code: params["code"], grant_type: "authorization_code")
        athlete = Strava.Auth.get_athlete!(client)
        {:ok, assign(socket, name: athlete.firstname)}
      else
        send(self(), :auth)
        {:ok, assign(socket, name: "")}
      end
    else
      {:ok, assign(socket, name: "")}
    end
  end

  @impl true
  def handle_info(:auth, socket) do
    {:noreply,
     redirect(socket,
       external: Strava.Auth.authorize_url!(scope: "activity:read,activity:read_all")
     )}
  end
end
