defmodule YTD.Activities.Activity do
  @moduledoc """
  Schema for activity record.
  """

  use Ecto.Schema

  alias YTD.Users.User

  @type t :: %__MODULE__{
          id: integer() | nil,
          user_id: integer() | nil,
          user: User.t() | nil,
          strava_id: integer() | nil,
          type: String.t() | nil,
          name: String.t() | nil,
          distance: float() | nil,
          start_date: DateTime.t() | nil
        }

  schema "activities" do
    field :strava_id, :integer
    field :type, :string
    field :name, :string
    field :distance, :float
    field :start_date, :utc_datetime
    timestamps()
    belongs_to :user, User
  end
end
