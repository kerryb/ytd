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

  alias Plug.Conn
  alias YTD.Repo
  alias YTD.Users.SaveTokens

  plug :get_user_if_signed_in
  plug :authorise_with_strava_if_not_signed_in

  @spec get_user_if_signed_in(Conn.t(), keyword()) :: Conn.t()
  def get_user_if_signed_in(conn, _opts) do
    conn
    |> fetch_session()
    |> get_session("athlete_id")
    |> case do
      nil -> conn
      athlete_id -> assign(conn, :athlete_id, athlete_id)
    end
  end

  @spec authorise_with_strava_if_not_signed_in(Conn.t(), keyword()) :: Conn.t()
  def authorise_with_strava_if_not_signed_in(%{assigns: %{athlete_id: _}} = conn, _opts), do: conn

  def authorise_with_strava_if_not_signed_in(conn, opts) do
    get_token = Keyword.get(opts, :get_token, &Strava.Auth.get_token!/1)
    save_tokens = Keyword.get(opts, :save_tokens, &SaveTokens.call/3)

    conn
    |> fetch_query_params()
    |> case do
      %{query_params: %{"code" => code}} = conn ->
        client = get_token.(code: code, grant_type: "authorization_code")
        save_user_tokens(client, save_tokens)

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

  defp save_user_tokens(client, save_tokens) do
    Repo.transaction(
      save_tokens.(
        client.token.other_params["athlete"]["id"],
        client.token.access_token,
        client.token.refresh_token
      )
    )
  end
end
