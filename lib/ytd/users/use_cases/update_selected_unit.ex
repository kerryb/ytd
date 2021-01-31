defmodule YTD.Users.UpdateSelectedUnit do
  @moduledoc """
  Use case for updating a user's selected activity type.
  """

  alias Ecto.{Changeset, Multi}
  alias YTD.Strava.Tokens
  alias YTD.Users.User

  @spec call(User.t(), Tokens.t()) :: Multi.t()
  def call(user, type) do
    change = Changeset.change(user, selected_unit: type)
    Multi.update(Multi.new(), :save_selected_unit, change)
  end
end
