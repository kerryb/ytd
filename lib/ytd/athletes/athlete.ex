defmodule YTD.Athlete do
  @moduledoc """
  Schema for ahtlete record.
  """

  use Ecto.Schema

  schema "athletes" do
    field(:strava_id, :integer)
    field(:token, :string)
    field(:run_target, :integer)
    field(:ride_target, :integer)
    field(:swim_target, :integer)
    timestamps()
  end
end
