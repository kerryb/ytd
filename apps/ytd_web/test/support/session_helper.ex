defmodule SessionHelper do
  def prepare_session(conn) do
    session = Plug.Session.init(store: :cookie,
                                key: "_app",
                                encryption_salt: "foo",
                                signing_salt: "bar")

    conn
    |> Map.put(:secret_key_base, String.duplicate("x", 64))
    |> Plug.Session.call(session) 
    |> Plug.Conn.fetch_session
  end
end
