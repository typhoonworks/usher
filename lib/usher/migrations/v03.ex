defmodule Usher.Migrations.V03 do
  @moduledoc """
  Adds InvitationUsage table for tracking invitation usage.

  Drops the joined_count field from the Invitation table, as the count
  can be derived from the InvitationUsage records.
  """
  use Ecto.Migration

  alias Usher.Config

  def up(opts) do
    table_name = Keyword.get(opts, :table_name, "usher_invitation_usages")
    invitations_table_name = Keyword.get(opts, :invitations_table_name, Config.table_name())
    table_opts = Keyword.take(opts, [:prefix])

    create table(table_name, [primary_key: false] ++ table_opts) do
      add(:id, :uuid, primary_key: true)

      add(:invitation_id, references(invitations_table_name, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:entity_type, :string, null: false)
      add(:entity_id, :string, null: false)
      add(:action, :string, null: false)
      add(:metadata, :map, default: %{}, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(index(table_name, [:invitation_id]))
    create(index(table_name, [:entity_type, :entity_id]))
    create(index(table_name, [:action]))
    create(index(table_name, [:inserted_at]))

    # Update version comment to track migration state
    prefix = Keyword.get(opts, :prefix, "public")
    execute("COMMENT ON TABLE #{prefix}.#{table_name} IS 'v03'")
  end

  def down(opts) do
    table_name = Keyword.get(opts, :table_name, "usher_invitation_usages")

    drop(table(table_name))
  end
end
