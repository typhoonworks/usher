defmodule Usher.Test.Repo.Migrations.MigrateToVersion04 do
  use Ecto.Migration

  def change do
    Usher.Migration.migrate_to_version("v04")
  end
end
