# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule YTD.Users do
  @moduledoc """
  Context to handle persistance of users.
  """

  @behaviour YTD.Users.API
  use Boundary, top_level?: true, deps: [Ecto, YTD.Repo], exports: [UpdateTokens]

  alias YTD.Repo

  alias YTD.Users.{
    API,
    Create,
    Queries,
    SaveTarget,
    UpdateName,
    UpdateSelectedActivityType,
    UpdateSelectedUnit,
    UpdateTokens
  }

  @impl API
  def get_user_from_athlete_id(athlete_id) do
    athlete_id |> Queries.get_user_from_athlete_id() |> Repo.one()
  end

  @impl API
  def get_targets(user) do
    user
    |> Queries.get_targets()
    |> Repo.all()
    |> Enum.into(%{}, &{&1.activity_type, &1})
  end

  @impl API
  def save_user_tokens(tokens) do
    case get_user_from_athlete_id(tokens.athlete_id) do
      nil ->
        {:ok, _result} = tokens |> Create.call() |> Repo.transaction()

      user ->
        {:ok, _result} =
          user
          |> UpdateTokens.call(tokens.access_token, tokens.refresh_token)
          |> Repo.transaction()
    end

    :ok
  end

  @impl API
  def save_activity_type(user, type) do
    {:ok, _result} = user |> UpdateSelectedActivityType.call(type) |> Repo.transaction()
    :ok
  end

  @impl API
  def save_unit(user, unit) do
    {:ok, _result} = user |> UpdateSelectedUnit.call(unit) |> Repo.transaction()
    :ok
  end

  @impl API
  def save_target(user, activity_type, target, unit) do
    {:ok, _result} = user |> SaveTarget.call(activity_type, target, unit) |> Repo.transaction()
    :ok
  end

  @impl API
  def update_name(pid, user) do
    {:ok, athlete} = strava_api().get_athlete_details(user)
    name = "#{athlete.firstname} #{athlete.lastname}"

    unless user.name == name do
      {:ok, %{update_name: updated_user}} = user |> UpdateName.call(name) |> Repo.transaction()
      send(pid, {:name_updated, updated_user})
    end

    :ok
  end

  defp strava_api, do: Application.fetch_env!(:ytd, :strava_api)
end
