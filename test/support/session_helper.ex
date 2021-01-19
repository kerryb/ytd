defmodule SessionHelper do
  @moduledoc """
  Helper to initialise the session for liveview tests.
  """

  @spec prepare_session(Plug.Conn.t()) :: Plug.Conn.t()
  def prepare_session(conn) do
    session =
      Plug.Session.init(
        store: :cookie,
        key: "_app",
        encryption_salt: "foo",
        signing_salt: "bar"
      )

    conn
    |> Map.put(:secret_key_base, String.duplicate("x", 64))
    |> Plug.Session.call(session)
    |> Plug.Conn.fetch_session()
  end
end
