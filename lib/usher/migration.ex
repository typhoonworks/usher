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
          migrate_to_version("v03")
        end
      end

  ### For existing installations upgrading:

      defmodule MyApp.Repo.Migrations.UpgradeUsherInvitations do
        use Ecto.Migration
        import Usher.Migration

        def change do
          migrate_to_version("v03")
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
  def migrate_to_version(version) do
    if version not in @all_versions do
      raise ArgumentError,
            "Invalid migration version: #{version}. Valid versions are: #{@all_versions}"
    end

    current_version = get_current_version()

    if current_version == version do
      :ok
    else
      apply_migrations_from_to(current_version, version)
    end
  end

  defp get_current_version(opts \\ []) do
    prefix = Keyword.get(opts, :prefix, "public")

    case usher_repo().query(
           "SELECT obj_description(oid) FROM pg_class WHERE relname = '#{@invitations_table_name}' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = '#{prefix}')"
         ) do
      {:ok, %{rows: [[version]]}} when is_binary(version) -> version
      {:ok, %{rows: [[nil]]}} -> check_legacy_table(opts)
      {:ok, %{rows: []}} -> nil
      _ -> nil
    end
  end

  # Check if table exists but has no version comment (legacy installation)
  defp check_legacy_table(opts) do
    prefix = Keyword.get(opts, :prefix, "public")

    case usher_repo().query(
           "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = '#{@invitations_table_name}' AND table_schema = '#{prefix}')"
         ) do
      {:ok, %{rows: [[true]]}} -> "legacy"
      _ -> nil
    end
  end

  defp apply_migrations_from_to(from_version, to_version, opts \\ []) do
    versions = get_migration_path(from_version, to_version)

    Enum.each(versions, fn version ->
      migration_module = Module.concat([Usher.Migrations, String.upcase(version)])
      migration_module.up(opts)
    end)
  end

  @doc false
  def get_migration_path(from_version, to_version) do
    start_index =
      case from_version do
        nil -> 0
        # Skip v01 for legacy installations
        "legacy" -> 1
        version -> Enum.find_index(@all_versions, &(&1 == version)) + 1
      end

    end_index = Enum.find_index(@all_versions, &(&1 == to_version))

    if start_index <= end_index do
      Enum.slice(@all_versions, start_index..end_index)
    else
      []
    end
  end

  defp usher_repo, do: Config.repo()
end
