defmodule Usher.Test.Repo.Migrations.MigrateToVersion03 do
  use Ecto.Migration

  def change do
    Usher.Migration.migrate_to_version(3)
  end
end
