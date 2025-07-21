defmodule Usher.Migrations.V01 do
  @moduledoc """
  Initial table structure for Usher invitations.

  This migration creates the base invitations table with:
  - UUID primary key
  - Token field with unique index
  - Expiration tracking
  - Join count tracking
  - Timestamps
  """

  use Ecto.Migration

  def up(opts) do
    table_opts = Keyword.take(opts, [:prefix])

    create table(:usher_invitations, [primary_key: false] ++ table_opts) do
      add(:id, :uuid, primary_key: true)
      add(:token, :string, null: false)
      add(:expires_at, :utc_datetime, null: false)
      add(:joined_count, :integer, default: 0, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:usher_invitations, [:token], name: :usher_invitations_token_index))
    create(index(:usher_invitations, [:expires_at]))

    # Add version comment to track migration state
    prefix = Keyword.get(opts, :prefix, "public")
    execute("COMMENT ON TABLE #{prefix}.usher_invitations IS 'v01'")
  end

  def down(opts) do
    drop(table(:usher_invitations, opts))
  end
end
