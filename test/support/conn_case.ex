# credo:disable-for-this-file Credo.Check.Readability.AliasAs
defmodule YTDWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use YTDWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use Boundary, top_level?: true, check: [out: false]
  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      # Import conveniences for testing with connections
      use YTDWeb, :verified_routes

      import Phoenix.ConnTest
      import Plug.Conn
      import YTD.Factory
      import YTDWeb.ConnCase

      # The default endpoint for testing
      @endpoint YTDWeb.Endpoint
    end
  end

  setup tags do
    :ok = Sandbox.checkout(YTD.Repo)

    unless tags[:async] do
      Sandbox.mode(YTD.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
