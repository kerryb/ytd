defmodule YTDWeb.AuthPlug do
  use Plug.Builder

  alias YTD.Users

  plug :get_user_if_signed_in
  plug :authorise_with_strava_if_not_signed_in

  def get_user_if_signed_in(conn, _opts) do
    conn
    |> fetch_session()
    |> get_session("athlete_id")
    |> case do
      nil -> conn
      athlete_id -> assign(conn, :athlete_id, athlete_id)
    end
  end

  def authorise_with_strava_if_not_signed_in(%{assigns: %{athlete_id: _}} = conn, _opts), do: conn

  def authorise_with_strava_if_not_signed_in(conn, _opts) do
    conn
    |> fetch_query_params()
    |> case do
      %{query_params: %{"code" => code}} = conn ->
        client = Strava.Auth.get_token!(code: code, grant_type: "authorization_code")
        save_user_tokens(client)

        conn
        |> put_session("athlete_id", client.token.other_params["athlete"]["id"])
        |> Phoenix.Controller.redirect(to: "/")
        |> halt()

      conn ->
        conn
        |> Phoenix.Controller.redirect(
          external: Strava.Auth.authorize_url!(scope: "activity:read,activity:read_all")
        )
        |> halt()
    end
  end

  defp save_user_tokens(client) do
    Users.save_tokens(
      client.token.other_params["athlete"]["id"],
      client.token.access_token,
      client.token.refresh_token
    )
  end
end
