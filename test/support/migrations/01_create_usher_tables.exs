defmodule Usher.Test.Repo.Migrations.CreateUsherTables do
  use Ecto.Migration

  import Usher.Migration

  def change do
    create_usher_invitations_table()
  end
end
