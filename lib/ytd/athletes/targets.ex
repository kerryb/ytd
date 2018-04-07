defmodule YTD.Athletes.Targets do
  @moduledoc """
  Functions allowing athletes to store annual targets for each activity.
  """

  alias Ecto.Changeset
  alias YTD.{Athletes, Repo}

  def set_run_target(id, 0), do: set_run_target(id, nil)

  def set_run_target(id, target) do
    id
    |> Athletes.find_by_strava_id()
    |> Changeset.change(run_target: target)
    |> Repo.update()

    :ok
  end

  def set_ride_target(id, 0), do: set_ride_target(id, nil)

  def set_ride_target(id, target) do
    id
    |> Athletes.find_by_strava_id()
    |> Changeset.change(ride_target: target)
    |> Repo.update()

    :ok
  end

  def set_swim_target(id, 0), do: set_swim_target(id, nil)

  def set_swim_target(id, target) do
    id
    |> Athletes.find_by_strava_id()
    |> Changeset.change(swim_target: target)
    |> Repo.update()

    :ok
  end
end
