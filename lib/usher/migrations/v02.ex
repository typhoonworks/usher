defmodule Usher.Migrations.V02 do
  @moduledoc """
  Adds name field to Usher invitations.

  This migration adds:
  - A name field to track invitation names
  """

  use Ecto.Migration

  def up(opts) do
    table_name = Keyword.get(opts, :table_name, "usher_invitations")

    alter table(table_name) do
      add(:name, :string, null: true)
    end

    # Update version comment to track migration state
    prefix = Keyword.get(opts, :prefix, "public")
    execute("COMMENT ON TABLE #{prefix}.#{table_name} IS 'v02'")
  end

  def down(opts) do
    table_name = Keyword.get(opts, :table_name, "usher_invitations")

    alter table(table_name) do
      remove(:name)
    end

    # Revert version comment
    prefix = Keyword.get(opts, :prefix, "public")
    execute("COMMENT ON TABLE #{prefix}.#{table_name} IS 'v01'")
  end
end
