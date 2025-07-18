defmodule Usher.Migration do
  @moduledoc """
  Migration helpers for creating and upgrading Usher tables.

  Use this module in your application's migrations to create the necessary
  database tables for Usher.

  ## Versioned Migrations

  Starting with v0.2.0, Usher supports versioned migrations to allow incremental
  updates to the database schema. This is useful for existing installations that
  need to upgrade to new versions without losing data.

  ### For new installations:

      defmodule MyApp.Repo.Migrations.CreateUsherInvitations do
        use Ecto.Migration
        import Usher.Migration

        def change do
          migrate_to_latest()
        end
      end

  ### For existing installations upgrading:

      defmodule MyApp.Repo.Migrations.UpgradeUsherInvitations do
        use Ecto.Migration
        import Usher.Migration

        def change do
          migrate_to_latest()
        end
      end

  The `migrate_to_latest/1` function will automatically detect the current version
  and apply only the necessary migrations to reach the latest version.
  """
  use Ecto.Migration

  alias Usher.Config

  @current_version "v02"

  @doc """
  Migrates the Usher tables to the latest version.

  This function automatically detects the current migration version and applies
  only the necessary migrations to reach the latest version. It's safe to run
  multiple times.

  ## Options

    * `:table_name` - Custom table name (defaults to configured table name)
    * `:prefix` - Schema prefix for the table

  ## Examples

      # Migrate to latest with defaults
      migrate_to_latest()

      # Migrate with custom options
      migrate_to_latest(table_name: "my_invitations", prefix: "public")
  """
  def migrate_to_latest(opts \\ []) do
    table_name = Keyword.get(opts, :table_name, Config.table_name())
    current_version = get_current_version(table_name, opts)

    case current_version do
      nil ->
        # Fresh installation - run all migrations
        apply_migrations_from_to(nil, @current_version, opts)

      @current_version ->
        # Already at latest version
        :ok

      version ->
        # Upgrade from current version to latest
        apply_migrations_from_to(version, @current_version, opts)
    end
  end

  defp get_current_version(table_name, opts) do
    prefix = Keyword.get(opts, :prefix, "public")

    case usher_repo().query(
           "SELECT obj_description(oid) FROM pg_class WHERE relname = '#{table_name}' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = '#{prefix}')"
         ) do
      {:ok, %{rows: [[version]]}} when is_binary(version) -> version
      {:ok, %{rows: [[nil]]}} -> check_legacy_table(table_name, opts)
      {:ok, %{rows: []}} -> nil
      _ -> nil
    end
  end

  defp check_legacy_table(table_name, opts) do
    # Check if table exists but has no version comment (legacy installation)
    prefix = Keyword.get(opts, :prefix, "public")

    case usher_repo().query(
           "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = '#{table_name}' AND table_schema = '#{prefix}')"
         ) do
      {:ok, %{rows: [[true]]}} -> "legacy"
      _ -> nil
    end
  end

  defp apply_migrations_from_to(from_version, to_version, opts) do
    versions = get_migration_path(from_version, to_version)

    Enum.each(versions, fn version ->
      migration_module = Module.concat([Usher.Migrations, String.upcase(version)])
      migration_module.up(opts)
    end)
  end

  @doc false
  def get_migration_path(from_version, to_version) do
    all_versions = ["v01", "v02"]

    start_index =
      case from_version do
        nil -> 0
        # Skip v01 for legacy installations
        "legacy" -> 1
        version -> Enum.find_index(all_versions, &(&1 == version)) + 1
      end

    end_index = Enum.find_index(all_versions, &(&1 == to_version))

    if start_index <= end_index do
      Enum.slice(all_versions, start_index..end_index)
    else
      []
    end
  end

  defp usher_repo do
    Config.repo()
  end
end
