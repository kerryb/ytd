defmodule YTD.Subscriptions.Subscription do
  @moduledoc """
  Schema for singleton subscription record.
  """

  use Ecto.Schema

  @type t :: %__MODULE__{}

  schema "subscription" do
    field :strava_id, :integer
    timestamps()
  end
end
