defmodule YTD.IntegrationTest do
  @moduledoc """
  This is a smoke test which actually hits Strava for auth and data fetching.
  It is tagged as `integration`, and can be excluded using `mix test
  --exclude=integration` (or `make unit-test`). The environment variables
  `YTD_STRAVA_EMAIL` and `YTD_STRAVA_PASSWORD` need to be set.
  """

  use YTD.DataCase, async: false
  use Wallaby.Feature

  @moduletag :integration

  feature "authentication with Strava", %{session: session} do
    email = System.fetch_env!("YTD_STRAVA_EMAIL")
    password = System.fetch_env!("YTD_STRAVA_PASSWORD")

    session
    |> visit("/")
    |> fill_in(Query.text_field("email"), with: email)
    |> fill_in(Query.text_field("password"), with: password)
    |> click(Query.button("login-button"))
    |> click(Query.button("Authorize"))
    |> assert_text("Kerry")
  end
end
