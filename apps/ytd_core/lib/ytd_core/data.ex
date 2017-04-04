defmodule YTDCore.Data do
  @moduledoc """
  A struct holding the data to be displayed for an athlete.
  """

  @type t :: %__MODULE__{ytd: float}
  defstruct [:ytd]
end
