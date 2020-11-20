defmodule YTD.IntegrationTest do
  use YTD.DataCase, async: false
  use Wallaby.Feature

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
