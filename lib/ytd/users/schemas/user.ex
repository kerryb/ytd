defmodule YTD.Users.User do
  @moduledoc """
  Schema for user record.
  """

  use Ecto.Schema

  alias YTD.Activities.Activity
  alias YTD.Users.Target

  @type t :: %__MODULE__{
          id: integer() | nil,
          athlete_id: integer() | nil,
          name: String.t() | nil,
          access_token: String.t() | nil,
          refresh_token: String.t() | nil,
          selected_activity_type: String.t(),
          selected_unit: String.t()
        }

  schema "users" do
    field :athlete_id, :integer
    field :access_token, :string
    field :name, :string
    field :refresh_token, :string
    field :selected_activity_type, :string
    field :selected_unit, :string
    timestamps()
    has_many :activities, Activity
    has_many :targets, Target
  end
end
