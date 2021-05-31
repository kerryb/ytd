# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule YTD.Strava do
  @moduledoc """
  Wrapper for calls to the Strava API.
  """

  @behaviour YTD.Strava.API

  use Boundary, top_level?: true, deps: [Strava, YTD.Users.Tokens]

  alias Strava.Auth
  alias YTD.Activities
  alias YTD.Strava.API

  @impl API
  def authorize_url do
    Auth.authorize_url!(scope: "activity:read,activity:read_all")
  end

  @impl API
  def get_tokens_from_code(code) do
    client = Auth.get_token!(code: code, grant_type: "authorization_code")
    YTD.Strava.Tokens.new(client)
  end

  @impl API
  def stream_activities_since(pid, user, timestamp) do
    client = client(user)

    Strava.Paginator.stream(&Strava.Activities.get_logged_in_athlete_activities(client, &1))
    |> Stream.take_while(&(DateTime.compare(&1.start_date, timestamp) == :gt))
    |> Enum.each(&new_activity_received(pid, user, &1))

    :ok
  end

  @impl API
  def get_athlete_details(user) do
    user |> client() |> Strava.Athletes.get_logged_in_athlete()
  end

  defp client(user) do
    Strava.Client.new(user.access_token,
      refresh_token: user.refresh_token,
      token_refreshed:
        &YTD.Users.Tokens.update_user_tokens(user, &1.token.access_token, &1.token.refresh_token)
    )
  end

  defp new_activity_received(pid, user, activity) do
    Activities.save_activity(user, activity)
    send(pid, {:new_activity, activity})
  end
end
