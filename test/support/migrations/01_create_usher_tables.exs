defmodule Usher.Test.Repo.Migrations.CreateUsherTables do
  use Ecto.Migration

  import Usher.Migration

  def change do
    migrate_to_version(2)
  end
end
