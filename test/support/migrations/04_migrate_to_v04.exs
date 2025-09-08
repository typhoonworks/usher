defmodule Usher.Test.Repo.Migrations.MigrateToVersion04 do
  use Ecto.Migration

  def up do
    Usher.Migration.migrate_to_version(4)
  end

  def down do
    Usher.Migration.migrate_to_version(3)
  end
end
