defmodule Usher.Migration do
  @moduledoc """
  Migration helpers for creating Usher tables.

  Use this module in your application's migrations to create the necessary
  database tables for Usher.
  """
  use Ecto.Migration

  alias Usher.Config

  @doc """
  Creates the usher_invitations table.

  ## Usage

  In your migration file:

      defmodule MyApp.Repo.Migrations.CreateUsherInvitations do
        use Ecto.Migration
        import Usher.Migration

        def change do
          create_usher_invitations_table()
        end
      end

  ## Options

    * `:table_name` - Custom table name (defaults to configured table name)
    * `:prefix` - Schema prefix for the table

  ## Examples

      # Default table name
      create_usher_invitations_table()

      # Custom table name
      create_usher_invitations_table(table_name: "my_invitations")

      # With schema prefix
      create_usher_invitations_table(prefix: "usher")
  """
  def create_usher_invitations_table(opts \\ []) do
    table_name = Keyword.get(opts, :table_name, Config.table_name())
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
  end

  @doc """
  Drops the usher_invitations table.

  ## Usage

      drop_usher_invitations_table()

  ## Options

    * `:table_name` - Custom table name (defaults to configured table name)

  ## Examples

      # Default table name
      drop_usher_invitations_table()

      # Custom table name
      drop_usher_invitations_table(table_name: "my_invitations")
  """
  def drop_usher_invitations_table(opts \\ []) do
    table_name = Keyword.get(opts, :table_name, Config.table_name())
    drop(table(table_name))
  end
end
