defmodule YTD.Users.User do
  @moduledoc """
  Schema for user record.
  """

  use Ecto.Schema

  alias YTD.Activities.Activity

  @type t :: %__MODULE__{
          id: integer() | nil,
          athlete_id: integer() | nil,
          access_token: String.t() | nil,
          refresh_token: String.t() | nil,
          run_target: integer() | nil,
          ride_target: integer() | nil,
          swim_target: integer() | nil,
          selected_activity_type: String.t(),
          selected_unit: String.t()
        }

  schema "users" do
    field :athlete_id, :integer
    field :access_token, :string
    field :refresh_token, :string
    field :run_target, :integer
    field :ride_target, :integer
    field :swim_target, :integer
    field :selected_activity_type, :string
    field :selected_unit, :string
    timestamps()
    has_many :activities, Activity
  end
end
