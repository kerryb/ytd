defmodule YTD.Users.SaveTarget do
  @moduledoc """
  Use case for setting a user's target for an activity type.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias YTD.Users.Target
  alias YTD.Users.User

  @spec call(User.t(), String.t(), String.t(), String.t()) :: Multi.t()
  def call(user, activity_type, "", _unit) do
    Multi.delete_all(
      Multi.new(),
      :delete_target,
      from(t in Target, where: t.user_id == ^user.id, where: t.activity_type == ^activity_type)
    )
  end

  def call(user, activity_type, target, unit) do
    target = %Target{
      user_id: user.id,
      activity_type: activity_type,
      target: String.to_integer(target),
      unit: unit
    }

    Multi.insert(Multi.new(), :save_target, target,
      on_conflict: {:replace, [:target, :unit]},
      conflict_target: [:user_id, :activity_type]
    )
  end
end
