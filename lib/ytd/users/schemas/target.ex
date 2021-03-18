defmodule YTD.Users.Target do
  @moduledoc """
  Schema for target record.
  """

  use Ecto.Schema

  alias YTD.Users.User

  @type t :: %__MODULE__{
          id: integer() | nil,
          user_id: integer() | nil,
          activity_type: String.t() | nil,
          target: integer() | nil,
          unit: String.t() | nil
        }

  schema "targets" do
    belongs_to :user, User
    field :activity_type, :string
    field :target, :integer
    field :unit, :string
    timestamps()
  end
end
