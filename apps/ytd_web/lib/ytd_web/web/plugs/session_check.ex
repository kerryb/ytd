defmodule YTDWeb.Web.Plugs.SessionCheck do
  @moduledoc """
  A plug to check whether the user has an active session. If an athlete ID is
  found in the session it allows the request to continue, otherwise it halts
  with a redirect to the authentication page.
  """
  import Plug.Conn
  alias Phoenix.Controller
  alias YTDWeb.Web.Router.Helpers
  alias Strava.Auth

  def init(opts), do: opts

  @spec call(Plug.Conn.t, term) :: Plug.Conn.t
  def call(conn, _opts) do
    if conn |> fetch_session |> get_session(:athlete_id) do
      conn
    else
      conn
      |> assign(:auth_url, Auth.authorize_url!)
      |> Controller.redirect(to: Helpers.auth_path(conn, :show))
      |> halt
    end
  end
end
