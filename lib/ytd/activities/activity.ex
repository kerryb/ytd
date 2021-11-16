defmodule YTD.Activities.Activity do
  @moduledoc """
  Schema for activity record.
  """

  use Ecto.Schema

  alias Strava.SummaryActivity
  alias YTD.Users.User

  @type t :: %__MODULE__{}

  schema "activities" do
    field :strava_id, :integer
    field :type, :string
    field :name, :string
    field :distance, :float
    field :start_date, :utc_datetime
    timestamps()
    belongs_to :user, User
  end

  @spec from_strava_activity(SummaryActivity.t(), User.t()) :: t()
  def from_strava_activity(summary, user) do
    %__MODULE__{
      user_id: user.id,
      strava_id: summary.id,
      type: summary.type,
      name: summary.name,
      distance: summary.distance,
      start_date: summary.start_date
    }
  end
end
