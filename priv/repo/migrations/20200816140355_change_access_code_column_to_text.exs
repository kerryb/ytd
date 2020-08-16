defmodule Ytd.Repo.Migrations.ChangeAccessCodeColumnToText do
  use Ecto.Migration

  def change do
    alter table(:athletes) do
      modify :access_token, :text, from: :string
    end
  end
end
