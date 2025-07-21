defmodule Usher.Test.Repo.Migrations.UsherInvitationsTableRename do
  use Ecto.Migration

  def up do
    # Check if usher_invitations table exists using raw SQL
    result = repo().query!("SELECT to_regclass('usher_invitations');")

    table_exists? =
      case result.rows do
        [[value]] when not is_nil(value) -> true
        _ -> false
      end

    if not table_exists? do
      rename(table(:your_invitations_table_name), to: table(:usher_invitations))
    end
  end

  def down do
    rename(table(:usher_invitations), to: table(:your_invitations_table_name))
  end
end
