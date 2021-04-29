defmodule YTD.Users.UpdateName do
  @moduledoc """
  Use case for updating a user's name.
  """

  alias Ecto.{Changeset, Multi}
  alias YTD.Users.User

  @spec call(User.t(), String.t()) :: Multi.t()
  def call(user, name) do
    change = Changeset.change(user, name: name)
    Multi.update(Multi.new(), :update_name, change)
  end
end
