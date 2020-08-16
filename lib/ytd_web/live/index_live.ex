defmodule YTDWeb.IndexLive do
  @moduledoc """
  Live view for main index page.
  """

  use YTDWeb, :live_view

  alias Strava.{Athletes, Client}
  alias YTD.Users

  @impl true
  def mount(_params, session, socket) do
    user = Users.get_user_from_athlete_id(session["athlete_id"])
    client = Client.new(user.access_token, refresh_token: user.refresh_token)
    {:ok, athlete} = Athletes.get_logged_in_athlete(client)
    {:ok, assign(socket, user: user, athlete: athlete, client: client)}
  end
end
