defmodule YTDWeb.AuthPlug do
  @moduledoc """
  A plug to handle authentication before calling the live view.

  If there is a strava athlete ID in the session, then it is assigned as
  `:athlete_id`.

  Otherwise the user is redirected to the Strava auth page, and the oAuth dance
  is handled, which eventually results in a user being created or updated in
  the database, and the athlete ID being added to the session to trigger the
  first case above.
  """

  use Plug.Builder

  alias Phoenix.Controller
  alias Plug.Conn
  alias YTD.{Strava, Users}
  alias YTDWeb.AuthView

  plug :get_user_if_signed_in
  plug :authorize_with_strava_if_not_signed_in

  @spec get_user_if_signed_in(Conn.t(), keyword()) :: Conn.t()
  def get_user_if_signed_in(conn, opts) do
    conn
    |> fetch_session()
    |> get_session("athlete_id")
    |> case do
      nil -> conn
      athlete_id -> assign_athlete_id_if_user_exists(conn, athlete_id, opts)
    end
  end

  defp assign_athlete_id_if_user_exists(conn, athlete_id, opts) do
    users = Keyword.get(opts, :users, Users)

    if users.get_user_from_athlete_id(athlete_id) do
      assign(conn, :athlete_id, athlete_id)
    else
      conn
    end
  end

  @spec authorize_with_strava_if_not_signed_in(Conn.t(), keyword()) :: Conn.t()
  def authorize_with_strava_if_not_signed_in(%{assigns: %{athlete_id: _}} = conn, _opts), do: conn

  def authorize_with_strava_if_not_signed_in(conn, opts) do
    users = Keyword.get(opts, :users, Users)
    strava = Keyword.get(opts, :strava, Strava)

    conn
    |> fetch_query_params()
    |> case do
      %{query_params: %{"code" => code}} = conn ->
        tokens = strava.get_tokens_from_code(code)
        users.save_user_tokens(tokens)

        conn
        |> put_session("athlete_id", tokens.athlete_id)
        |> Phoenix.Controller.redirect(to: "/")
        |> halt()

      conn ->
        conn
        |> Controller.put_view(AuthView)
        |> Conn.assign(:auth_url, strava.authorize_url)
        |> Controller.render("index.html")
        |> halt()
    end
  end
end
