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
    table_name = Keyword.get(opts, :table_name, "usher_invitations")
    table_opts = Keyword.take(opts, [:prefix])

    create table(table_name, [primary_key: false] ++ table_opts) do
      add(:id, :uuid, primary_key: true)
      add(:token, :string, null: false)
      add(:expires_at, :utc_datetime, null: false)
      add(:joined_count, :integer, default: 0, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(table_name, [:token], name: :"#{table_name}_token_index"))
    create(index(table_name, [:expires_at]))

    # Add version comment to track migration state
    prefix = Keyword.get(opts, :prefix, "public")
    execute("COMMENT ON TABLE #{prefix}.#{table_name} IS 'v01'")
  end

  def down(opts) do
    table_name = Keyword.get(opts, :table_name, "usher_invitations")
    drop(table(table_name))
  end
end
