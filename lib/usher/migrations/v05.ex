defmodule Usher.Migrations.V05 do
  @moduledoc """
  Adds the `:custom_attributes` field to the `Usher.Invitation` schema.

  Custom attributes allow users of the library to fetch and use these custom
  attributes after validating the invitation, for example, for setting
  attributes for the newly created user.
  """
  use Ecto.Migration

  def up(opts) do
    table_opts = Keyword.take(opts, [:prefix])

    alter table(:usher_invitations, table_opts) do
      add(:custom_attributes, :map)
    end

    # Update version comment to track migration state
    prefix = Keyword.get(opts, :prefix, "public")
    execute("COMMENT ON TABLE #{prefix}.usher_invitations IS 'v05'")
  end

  def down(opts) do
    table_opts = Keyword.take(opts, [:prefix])

    alter table(:usher_invitations, table_opts) do
      remove(:custom_attributes)
    end

    # Revert version comment
    prefix = Keyword.get(opts, :prefix, "public")
    execute("COMMENT ON TABLE #{prefix}.usher_invitations IS 'v04'")
  end
end
