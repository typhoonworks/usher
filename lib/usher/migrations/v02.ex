defmodule Usher.Migrations.V02 do
  @moduledoc """
  Adds name field to Usher invitations.

  This migration adds:
  - A name field to track invitation names
  """

  use Ecto.Migration

  def up(opts) do
    alter table(:usher_invitations, opts) do
      add(:name, :string, null: true)
    end

    # Update version comment to track migration state
    prefix = Keyword.get(opts, :prefix, "public")
    execute("COMMENT ON TABLE #{prefix}.usher_invitations IS 'v02'")
  end

  def down(opts) do
    alter table(:usher_invitations, opts) do
      remove(:name)
    end

    # Revert version comment
    prefix = Keyword.get(opts, :prefix, "public")
    execute("COMMENT ON TABLE #{prefix}.usher_invitations IS 'v01'")
  end
end
