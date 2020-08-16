defmodule YTD.Repo.Migrations.AddRefreshToken do
  use Ecto.Migration

  def change do
    alter table(:athletes) do
      add(:refresh_token, :text)
    end

    rename(table(:athletes), :token, to: :access_token)
  end
end
