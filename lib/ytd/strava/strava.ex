# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule YTD.Strava do
  @moduledoc """
  Wrapper for calls to the Strava API.
  """

  @behaviour YTD.Strava.API

  use Boundary, top_level?: true, deps: [Strava, YTD.Users.Tokens, YTDWeb]

  alias Strava.{Activities, Athletes, Auth, Client}
  alias YTD.Strava.API
  alias YTDWeb.Endpoint
  # credo:disable-for-next-line Credo.Check.Readability.AliasAs
  alias YTDWeb.Router.Helpers, as: Routes

  @impl API
  def authorize_url, do: Auth.authorize_url!(scope: "activity:read,activity:read_all")

  @impl API
  def get_tokens_from_code(code) do
    client = Auth.get_token!(code: code, grant_type: "authorization_code")
    YTD.Strava.Tokens.new(client)
  end

  @impl API
  def stream_activities_since(user, timestamp, callback) do
    client = client(user)

    Strava.Paginator.stream(&Activities.get_logged_in_athlete_activities(client, &1))
    |> Stream.take_while(&(DateTime.compare(&1.start_date, timestamp) == :gt))
    |> Enum.each(callback)

    :ok
  end

  @impl API
  def get_athlete_details(user), do: user |> client() |> Athletes.get_logged_in_athlete()

  @impl API
  def subscribe_to_events do
    case request_subscription() do
      {:ok, %{"id" => id}} -> {:ok, id}
      error -> error
    end
  end

  @impl API
  def get_activity(user, activity_id),
    do: user |> client() |> Activities.get_activity_by_id(activity_id)

  defp request_subscription do
    case :hackney.post(
           "https://www.strava.com/api/v3/push_subscriptions",
           [],
           {:form,
            [
              client_id: Application.get_env(:strava, :client_id),
              client_secret: Application.get_env(:strava, :client_secret),
              callback_url: Routes.events_url(Endpoint, :validate),
              verify_token: "ytd"
            ]},
           with_body: true
         ) do
      {:ok, 200, _headers, body} -> Jason.decode(body)
      error -> error
    end
  end

  defp client(user) do
    Client.new(user.access_token,
      refresh_token: user.refresh_token,
      token_refreshed:
        &YTD.Users.Tokens.update_user_tokens(user, &1.token.access_token, &1.token.refresh_token)
    )
  end
end
