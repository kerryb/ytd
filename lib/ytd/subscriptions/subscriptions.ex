defmodule YTD.Subscriptions do
  @moduledoc """
  Context for the subscription to the Strava events webhook API.
  """

  use Boundary, top_level?: true, deps: [Ecto, YTD.Repo]

  alias YTD.Repo
  alias YTD.Subscriptions.Subscription

  @doc """
  Subscribe to the Strava events webhook API. This is intended to be called
  manually once only, to set up the subscription.
  """
  @spec subscribe :: :ok | {:error, any()}
  def subscribe do
    case strava_api().subscribe_to_events() do
      {:ok, id} -> Repo.insert(%Subscription{strava_id: id})
      error -> error
    end
  end

  defp strava_api, do: Application.fetch_env!(:ytd, :strava_api)
end
