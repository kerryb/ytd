defmodule YTDWeb.EventsControllerTest do
  use YTDWeb.ConnCase, async: true

  describe "GET /webhooks/events" do
    test "echoes back the hub challenge" do
      conn = get(build_conn(), "/webhooks/events", %{"hub.challenge" => "foobar"})
      assert Jason.decode!(conn.resp_body) == %{"hub.challenge" => "foobar"}
    end
  end
end
