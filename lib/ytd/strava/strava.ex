# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule YTD.Strava do
  @moduledoc """
  Wrapper for calls to the Strava API.
  """

  @behaviour YTD.Strava.API

  alias Strava.Auth
  alias YTD.Strava.Tokens
  alias YTD.Users
  alias YTD.Users.User

  @spec authorize_url :: String.t() | no_return()
  def authorize_url do
    Auth.authorize_url!(scope: "activity:read,activity:read_all")
  end

  @spec get_tokens_from_code(String.t()) :: Tokens.t()
  def get_tokens_from_code(code) do
    client = Auth.get_token!(code: code, grant_type: "authorization_code")
    Tokens.new(client)
  end

  @spec stream_activities_since(pid(), User.t(), DateTime.t()) :: :ok
  def stream_activities_since(pid, user, timestamp) do
    client = client(user)

    Strava.Paginator.stream(&Strava.Activities.get_logged_in_athlete_activities(client, &1))
    |> Stream.take_while(&(DateTime.compare(&1.start_date, timestamp) == :gt))
    |> Enum.each(&broadcast_activity(pid, &1))

    broadcast_all_activities_fetched(pid)
    :ok
  end

  defp client(user) do
    Strava.Client.new(user.access_token,
      refresh_token: user.refresh_token,
      token_refreshed: &Users.update_user_tokens(user, &1)
    )
  end

  defp broadcast_activity(pid, activity) do
    send(pid, {:new_activity, activity})
  end

  defp broadcast_all_activities_fetched(pid) do
    send(pid, :all_activities_fetched)
  end
end
