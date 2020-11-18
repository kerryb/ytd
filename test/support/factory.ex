# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule YTD.Factory do
  @moduledoc """
  Test tactories, using ex_machina.
  """

  use ExMachina.Ecto, repo: YTD.Repo

  alias YTD.Users.User

  def user_factory do
    %User{
      athlete_id: sequence(:athlete_id, &(10_000_000 + &1)),
      access_token: sequence(:access_token, &"#{20_000_000 + &1}"),
      refresh_token: sequence(:refresh_token, &"#{30_000_000 + &1}")
    }
  end
end
