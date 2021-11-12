defmodule YTDWeb.EventsControllerTest do
  use YTDWeb.ConnCase, async: true
  import ExUnit.CaptureLog

  describe "GET /webhooks/events" do
    test "echoes back the hub challenge" do
      conn = get(build_conn(), "/webhooks/events", %{"hub.challenge" => "foobar"})
      assert Jason.decode!(conn.resp_body) == %{"hub.challenge" => "foobar"}
    end
  end

  describe "POST /webhooks/events" do
    test "logs the event (for now)" do
      assert capture_log(fn -> post(build_conn(), "/webhooks/events", %{"foo" => "bar"}) end) =~
               ~r/Received event: %{"foo" => "bar"}/
    end

    test "returns a 200 response" do
      conn = post(build_conn(), "/webhooks/events", %{"foo" => "bar"})
      assert text_response(conn, 200) =~ ""
    end
  end
end
