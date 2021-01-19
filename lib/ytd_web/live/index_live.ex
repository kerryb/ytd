defmodule YTDWeb.IndexLive do
  @moduledoc """
  Live view for main index page.
  """

  use YTDWeb, :live_view

  alias YTD.Users

  require Logger

  @impl true
  def mount(_params, session, socket) do
    user = Users.get_user_from_athlete_id(session["athlete_id"])
    {:ok, assign(socket, user: user, info: "Loading activities …")}
  end
end
