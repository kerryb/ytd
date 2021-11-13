defmodule YTD.SubscriptionsTest do
  use YTD.DataCase, async: true

  import Mox

  alias YTD.Subscriptions
  alias YTD.Subscriptions.Subscription

  describe "YTD.Subscriptions.subscribe/0" do
    test "creates a subscription record on success" do
      stub(StravaMock, :subscribe_to_events, fn -> {:ok, 1234} end)
      {:ok, _} = Subscriptions.subscribe()
      [subscription] = Repo.all(Subscription)
      assert subscription.strava_id == Decimal.new(1234)
    end

    test "returns the error on failure" do
      stub(StravaMock, :subscribe_to_events, fn -> {:error, "Failed"} end)
      assert Subscriptions.subscribe() == {:error, "Failed"}
    end
  end
end
