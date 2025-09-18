  defmodule Usher.Repo.Migrations.CreateUsherInvitations do
    use Ecto.Migration

    def up do
      Usher.Migration.migrate_to_version(4)
    end

    def down do
      Usher.Migration.migrate_to_version(1)
    end
end

