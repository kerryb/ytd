defmodule YTDWeb.EventsControllerTest do
  use YTDWeb.ConnCase, async: true

  import Mox

  describe "GET /webhooks/events" do
    test "echoes back the hub challenge" do
      conn = get(build_conn(), "/webhooks/events", %{"hub.challenge" => "foobar"})
      assert Jason.decode!(conn.resp_body) == %{"hub.challenge" => "foobar"}
    end
  end

  describe "POST /webhooks/events" do
    setup :verify_on_exit!

    test "reports activity creation events to the Activities context" do
      expect(ActivitiesMock, :activity_created, fn 5678, 1234 -> :ok end)

      conn =
        post(build_conn(), "/webhooks/events", %{
          "aspect_type" => "create",
          "event_time" => DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_unix(),
          "object_id" => 1234,
          "object_type" => "activity",
          "owner_id" => 5678,
          "updates" => %{}
        })

      assert text_response(conn, 200) =~ ""
    end

    test "reports activity update events to the Activities context" do
      expect(ActivitiesMock, :activity_updated, fn 5678, 1234 -> :ok end)

      conn =
        post(build_conn(), "/webhooks/events", %{
          "aspect_type" => "update",
          "event_time" => DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_unix(),
          "object_id" => 1234,
          "object_type" => "activity",
          "owner_id" => 5678,
          "updates" => %{}
        })

      assert text_response(conn, 200) =~ ""
    end

    test "reports activity deletion events to the Activities context" do
      expect(ActivitiesMock, :activity_deleted, fn 5678, 1234 -> :ok end)

      conn =
        post(build_conn(), "/webhooks/events", %{
          "aspect_type" => "delete",
          "event_time" => DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_unix(),
          "object_id" => 1234,
          "object_type" => "activity",
          "owner_id" => 5678,
          "updates" => %{}
        })

      assert text_response(conn, 200) =~ ""
    end

    test "reports athlete update events to the Users context" do
      expect(UsersMock, :athlete_updated, fn 1234, %{"authorized" => "false"} -> :ok end)

      conn =
        post(build_conn(), "/webhooks/events", %{
          "aspect_type" => "update",
          "event_time" => DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_unix(),
          "object_id" => 1234,
          "object_type" => "athlete",
          "owner_id" => 1234,
          "updates" => %{"authorized" => "false"}
        })

      assert text_response(conn, 200) =~ ""
    end

    test "reports athlete deletion (deauthorisation) events to the Users context" do
      expect(UsersMock, :athlete_deleted, fn 1234 -> :ok end)

      conn =
        post(build_conn(), "/webhooks/events", %{
          "aspect_type" => "delete",
          "event_time" => DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_unix(),
          "object_id" => 1234,
          "object_type" => "athlete",
          "owner_id" => 1234,
          "updates" => %{}
        })

      assert text_response(conn, 200) =~ ""
    end

    test "ignores other events" do
      conn =
        post(build_conn(), "/webhooks/events", %{
          "aspect_type" => "create",
          "event_time" => DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_unix(),
          "object_id" => 1234,
          "object_type" => "athlete",
          "owner_id" => 1234,
          "updates" => %{}
        })

      assert text_response(conn, 200) =~ ""
    end
  end
end
