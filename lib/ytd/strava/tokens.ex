defmodule YTD.Strava.Tokens do
  @moduledoc """
  A struct containing a Strava athlete ID and the related auth tokens.
  """

  @enforce_keys [:athlete_id, :access_token, :refresh_token]
  defstruct [:athlete_id, :access_token, :refresh_token]

  @type t :: %__MODULE__{
          athlete_id: integer(),
          access_token: String.t(),
          refresh_token: String.t()
        }

  @doc """
  Extract the tokens from a Strava API client struct.
  """
  @spec new(OAuth2.Client.t()) :: t()
  def new(client) do
    %__MODULE__{
      athlete_id: client.token.other_params["athlete"]["id"],
      access_token: client.token.access_token,
      refresh_token: client.token.refresh_token
    }
  end
end
