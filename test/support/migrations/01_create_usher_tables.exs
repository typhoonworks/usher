defmodule Usher.Test.Repo.Migrations.CreateUsherTables do
  use Ecto.Migration

  import Usher.Migration

  def change do
    migrate_to_latest()
  end
end
