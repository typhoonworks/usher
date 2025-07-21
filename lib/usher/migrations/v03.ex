defmodule Usher.Migrations.V03 do
  @moduledoc """
  Adds InvitationUsage table for tracking invitation usage.

  Drops the joined_count field from the Invitation table, as the count
  can be derived from the InvitationUsage records.
  """
  use Ecto.Migration

  def up(opts) do
    table_opts = Keyword.take(opts, [:prefix])

    create table(:usher_invitation_usages, [primary_key: false] ++ table_opts) do
      add(:id, :uuid, primary_key: true)

      add(:invitation_id, references(:usher_invitations, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:entity_type, :string, null: false)
      add(:entity_id, :string, null: false)
      add(:action, :string, null: false)
      add(:metadata, :map, default: %{}, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:usher_invitation_usages, [:invitation_id]))
    create(index(:usher_invitation_usages, [:entity_type, :entity_id]))
    create(index(:usher_invitation_usages, [:action]))
    create(index(:usher_invitation_usages, [:inserted_at]))

    # Update version comment to track migration state
    prefix = Keyword.get(opts, :prefix, "public")
    execute("COMMENT ON TABLE #{prefix}.usher_invitations IS 'v03'")
  end

  def down(opts) do
    drop(table(:usher_invitation_usages, opts))
  end
end
