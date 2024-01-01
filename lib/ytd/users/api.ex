defmodule YTD.Users.API do
  @moduledoc """
  API behaviour for the Users context.
  """

  alias Ecto.Multi
  alias YTD.Strava.Tokens
  alias YTD.Users.Target
  alias YTD.Users.User

  @type multi_result ::
          {:ok, any()}
          | {:error, any()}
          | {:error, Multi.name(), any(), %{required(Multi.name()) => any()}}

  @callback get_user_from_athlete_id(athlete_id :: integer()) :: User.t() | nil
  @callback get_targets(user :: User.t()) :: %{String.t() => Target.t()}
  @callback save_user_tokens(tokens :: Tokens.t()) :: :ok
  @callback save_activity_type(user :: User.t(), type :: String.t()) :: :ok
  @callback save_unit(user :: User.t(), unit :: String.t()) :: :ok
  @callback save_target(
              user :: User.t(),
              activity_type :: String.t(),
              target :: String.t(),
              unit :: String.t()
            ) :: :ok
  @callback update_name(User.t()) :: :ok
  @callback athlete_updated(athlete_id :: integer(), updates :: %{String.t() => String.t()}) ::
              :ok
  @callback athlete_deleted(athlete_id :: integer()) :: :ok
end
