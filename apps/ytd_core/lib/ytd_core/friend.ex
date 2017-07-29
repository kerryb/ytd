defmodule YTDCore.Friend do
  @moduledoc """
  A struct holding the data to be displayed for a friend in the leaderboard.
  """

  @type t :: %__MODULE__{name: String.t, profile_url: String.t, ytd: float}

  defstruct [:name, :profile_url, :ytd]
end
