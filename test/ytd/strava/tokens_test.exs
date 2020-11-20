defmodule YTD.Strava.TokensTest do
  use ExUnit.Case, async: true, async: true

  alias YTD.Strava.Tokens

  describe "YTD.Strava.Tokens.new/1" do
    test "creates a struct from a Strava API client" do
      client = %{
        token: %{
          access_token: "456",
          refresh_token: "789",
          other_params: %{"athlete" => %{"id" => "123"}}
        }
      }

      assert Tokens.new(client) == %Tokens{
               athlete_id: "123",
               access_token: "456",
               refresh_token: "789"
             }
    end
  end
end
