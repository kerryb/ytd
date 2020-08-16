defmodule YTD.Repo do
  use Ecto.Repo,
    otp_app: :ytd,
    adapter: Ecto.Adapters.Postgres
end
