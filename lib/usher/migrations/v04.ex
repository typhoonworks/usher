defmodule Usher.Migrations.V04 do
  @moduledoc """
  Makes the expires_at field nullable to support never-expiring invitations.

  This allows invitation links to be created without an expiration date,
  enabling "long-living" personal invitation links.
  """
  use Ecto.Migration

  def up(opts) do
    table_opts = Keyword.take(opts, [:prefix])

    alter table(:usher_invitations, table_opts) do
      modify(:expires_at, :utc_datetime, null: true)
    end

    # Update version comment to track migration state
    prefix = Keyword.get(opts, :prefix, "public")
    execute("COMMENT ON TABLE #{prefix}.usher_invitations IS 'v04'")
  end

  def down(opts) do
    table_opts = Keyword.take(opts, [:prefix])

    # In rollback, set a default expiration for any NULL values
    # before making the column non-nullable again
    execute("""
    UPDATE usher_invitations 
    SET expires_at = NOW() + INTERVAL '7 days' 
    WHERE expires_at IS NULL
    """)

    alter table(:usher_invitations, table_opts) do
      modify(:expires_at, :utc_datetime, null: false)
    end
  end
end
