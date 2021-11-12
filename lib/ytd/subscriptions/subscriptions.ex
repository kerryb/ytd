defmodule YTD.Subscriptions do
  @moduledoc """
  Context for the subscription to the Strava events webhook API.
  """

  use Boundary, top_level?: true, deps: [Ecto, YTD.Repo]
end
