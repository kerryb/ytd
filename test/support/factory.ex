# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule YTD.Factory do
  @moduledoc """
  Test tactories, using ex_machina.
  """

  use Boundary, top_level?: true, check: [out: false]
  use ExMachina.Ecto, repo: YTD.Repo

  alias YTD.Activities.Activity
  alias YTD.Users.{Target, User}

  def user_factory do
    %User{
      athlete_id: sequence(:athlete_id, &(10_000_000 + &1)),
      access_token: sequence(:access_token, &"#{20_000_000 + &1}"),
      refresh_token: sequence(:refresh_token, &"#{30_000_000 + &1}"),
      selected_activity_type: Enum.random(~w[Run Ride Swim Walk]),
      selected_unit: Enum.random(~w[miles km])
    }
  end

  def activity_factory do
    %Activity{
      user: build(:user),
      strava_id: sequence(:strava_activity_id, &(40_000_000 + &1)),
      type: Enum.random(["Run", "Ride", "Swim"]),
      name: Faker.Lorem.sentence(3),
      distance: :rand.uniform_real() * 100,
      start_date: DateTime.add(DateTime.utc_now(), -:rand.uniform(10_000_000), :second)
    }
  end

  def target_factory do
    %Target{
      user: build(:user),
      activity_type: Enum.random(["Run", "Ride", "Swim"]),
      target: :rand.uniform(3000),
      unit: Enum.random(["miles", "km"])
    }
  end
end
