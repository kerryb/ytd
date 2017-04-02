defmodule YTDWeb.PageControllerTest do
  use YTDWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ ~r/TODO/
  end
end
