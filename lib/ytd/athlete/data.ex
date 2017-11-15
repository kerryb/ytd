defmodule YTD.Athlete.Data do
  @moduledoc """
  A struct holding the data to be displayed for an athlete.
  """

  @type t :: %__MODULE__{profile_url: String.t,
    running: Values,
    cycling: Values,
    swimming: Values,
  }
  defstruct [
    :profile_url,
    :running,
    :cycling,
    :swimming,
  ]
end
