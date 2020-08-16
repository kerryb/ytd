defmodule YTD.Users.User do
  @moduledoc """
  Schema for user record.
  """

  use Ecto.Schema

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
