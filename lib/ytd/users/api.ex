defmodule YTD.Users.API do
  @moduledoc """
  API behaviour for the Users context.
  """

  alias Ecto.Multi
  alias YTD.Users.User

  @callback get_user_from_athlete_id(String.t()) :: User.t() | nil

  @callback save_user_tokens(String.t(), String.t(), String.t()) ::
              {:ok, any()}
              | {:error, any()}
              | {:error, Multi.name(), any(), %{required(Multi.name()) => any()}}
end
