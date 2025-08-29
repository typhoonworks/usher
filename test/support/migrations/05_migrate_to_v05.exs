defmodule Usher.Test.Repo.Migrations.MigrateToVersion05 do
  use Ecto.Migration

  def up do
    Usher.Migration.migrate_to_version("v05")
  end

  def down do
    Usher.Migration.migrate_to_version("v04")
  end
end
