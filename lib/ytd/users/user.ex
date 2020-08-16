defmodule YTD.Users.User do
  @moduledoc """
  Schema for user record.
  """

  use Ecto.Schema

  @type t :: %__MODULE__{
          id: integer() | nil,
          athlete_id: integer() | nil,
          access_token: String.t() | nil,
          refresh_token: String.t() | nil,
          run_target: integer() | nil,
          ride_target: integer() | nil,
          swim_target: integer() | nil
        }

  schema "users" do
    field(:athlete_id, :integer)
    field(:access_token, :string)
    field(:refresh_token, :string)
    field(:run_target, :integer)
    field(:ride_target, :integer)
    field(:swim_target, :integer)
    timestamps()
  end
end
