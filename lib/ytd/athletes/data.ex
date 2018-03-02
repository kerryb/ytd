defmodule YTD.Athletes.Data do
  @moduledoc """
  A struct holding the data to be displayed for an athlete.
  """

  @type t :: %__MODULE__{profile_url: String.t(), run: Values, ride: Values, swim: Values}
  defstruct [
    :profile_url,
    :run,
    :ride,
    :swim
  ]
end
