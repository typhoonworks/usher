defmodule Usher.Test.Repo.Migrations.Test do
  use Ecto.Migration

  def change do
    Usher.Migration.migrate_to_version("v03")
  end
end
