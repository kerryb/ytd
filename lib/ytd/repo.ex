defmodule YTD.Repo do
  use Boundary, top_level?: true, deps: [Ecto]
  use Ecto.Repo, otp_app: :ytd, adapter: Ecto.Adapters.Postgres
end
