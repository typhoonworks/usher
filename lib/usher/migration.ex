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

        def up do
          Usher.Migration.migrate_to_version("v04")
        end

        def down do
          Usher.Migration.migrate_to_version("v01")
        end
      end

  ### For existing installations upgrading:

      defmodule MyApp.Repo.Migrations.UpgradeUsherInvitations do
        use Ecto.Migration
        import Usher.Migration

        def up do
          Usher.Migration.migrate_to_version("v04")
        end

        def down do
          Usher.Migration.migrate_to_version("v03")
        end
      end
  """
  use Ecto.Migration

  alias Usher.Config

  @latest_version "v04"
  @all_versions ["v01", "v02", "v03", "v04"]
  @invitations_table_name "usher_invitations"

  @doc """
  Returns the latest version of the Usher migrations.
  """
  @spec latest_version() :: String.t()
  def latest_version, do: @latest_version

  @doc """
  Returns a list of all available migration versions.
  """
  @spec all_versions() :: [String.t()]
  def all_versions, do: @all_versions

  @doc """
  Migrates the Usher tables to the latest version.

  This function is deprecated because it cannot be used more than once
  in your migration files. Use `migrate_to_version/1` instead to specify
  the exact version you want to migrate to.

  See the CHANGELOG for details on breaking changes.
  """
  @deprecated "Use `migrate_to_version/1` instead for migrations"
  def migrate_to_latest(_opts \\ []) do
    migrate_to_version("v02")
  end

  @doc """
  Migrates the Usher tables to a specific version.

  This function automatically detects the current migration version and applies
  only the necessary migrations to reach the latest version. It's safe to run
  multiple times.

  ## Parameters

    - `version`: The target version to migrate to, e.g. "v01", "v02", etc.

  ## Examples

      migrate_to_version("v03")
  """
  @spec migrate_to_version(String.t()) :: no_return()
  def migrate_to_version(to_version) do
    if to_version not in @all_versions do
      raise ArgumentError,
            "Invalid migration version: #{to_version}. Valid versions are: #{@all_versions}"
    end

    current_version = get_current_version()
    to_version = version_string_to_integer(to_version)

    if current_version == to_version do
      :ok
    else
      apply_migrations_from_to(current_version, to_version)
    end
  end

  defp get_current_version(opts \\ []) do
    prefix = Keyword.get(opts, :prefix, "public")

    case query_table_version(prefix) do
      version when version in @all_versions ->
        version_string_to_integer(version)

      "legacy" ->
        1

      nil ->
        0
    end
  end

  defp query_table_version(prefix) do
    table_comment =
      usher_repo().query("""
      SELECT obj_description(oid)
      FROM pg_class
      WHERE relname = '#{@invitations_table_name}'
        AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = '#{prefix}')
      """)

    case table_comment do
      {:ok, %{rows: [[version]]}} when is_binary(version) -> version
      {:ok, %{rows: []}} -> check_legacy_table(prefix)
    end
  end

  # Check if table exists but has no version comment (legacy installation)
  defp check_legacy_table(prefix) do
    legacy_table_exists =
      usher_repo().query("""
      SELECT EXISTS
      (
        SELECT 1
        FROM information_schema.tables
        WHERE table_name = '#{@invitations_table_name}'
          AND table_schema = '#{prefix}'
      )
      """)

    case legacy_table_exists do
      {:ok, %{rows: [[true]]}} -> "legacy"
      _ -> nil
    end
  end

  defp apply_migrations_from_to(from_version, to_version, opts \\ [])

  defp apply_migrations_from_to(from_version, to_version, opts)
       when from_version < to_version do
    all_versions = Enum.map(@all_versions, &version_string_to_integer/1)

    start_index = Enum.find_index(all_versions, &(&1 == from_version + 1))
    end_index = Enum.find_index(all_versions, &(&1 == to_version))
    versions = Enum.slice(all_versions, start_index..end_index)

    Enum.each(versions, fn version ->
      migration_module = Module.concat([Usher.Migrations, "V0" <> Integer.to_string(version)])
      migration_module.up(opts)
    end)
  end

  defp apply_migrations_from_to(from_version, to_version, opts)
       when from_version > to_version do
    all_versions = Enum.map(@all_versions, &version_string_to_integer/1)

    start_index = Enum.find_index(all_versions, &(&1 == from_version))
    end_index = Enum.find_index(all_versions, &(&1 == to_version + 1))
    versions = Enum.slice(all_versions, end_index..start_index) |> Enum.reverse()

    Enum.each(versions, fn version ->
      migration_module = Module.concat([Usher.Migrations, "V0" <> Integer.to_string(version)])
      migration_module.down(opts)
    end)
  end

  defp version_string_to_integer(version) when is_binary(version) do
    "v" <> version_number = version

    String.to_integer(version_number)
  end

  defp usher_repo, do: Config.repo()
end
