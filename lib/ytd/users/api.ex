defmodule YTD.Users.API do
  @moduledoc """
  API behaviour for the Users context.
  """

  alias Ecto.Multi
  alias OAuth2.Client
  alias YTD.Strava.Tokens
  alias YTD.Users.{Target, User}

  @type multi_result ::
          {:ok, any()}
          | {:error, any()}
          | {:error, Multi.name(), any(), %{required(Multi.name()) => any()}}

  @callback get_user_from_athlete_id(integer()) :: User.t() | nil
  @callback get_targets(User.t()) :: %{String.t() => Target.t()}
  @callback save_user_tokens(Tokens.t()) :: :ok
  @callback update_user_tokens(User.t(), Client.t()) :: :ok
  @callback save_activity_type(User.t(), String.t()) :: :ok
  @callback save_unit(User.t(), String.t()) :: :ok
  @callback save_target(User.t(), String.t(), String.t(), String.t()) :: :ok
  @callback update_name(pid(), User.t()) :: :ok
end
