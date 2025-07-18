defmodule Usher.MigrationTest do
  use ExUnit.Case, async: true

  alias Usher.Migration

  describe "get_migration_path/2" do
    test "returns correct path for fresh installation" do
      path = Migration.get_migration_path(nil, Migration.latest_version())
      assert path == Migration.all_versions()
    end

    test "returns correct path for legacy installation" do
      path = Migration.get_migration_path("legacy", "v02")
      assert path == ["v02"]
    end

    test "returns correct path for incremental upgrade" do
      path = Migration.get_migration_path("v01", "v02")
      assert path == ["v02"]
    end

    test "returns empty path when already at target version" do
      path = Migration.get_migration_path("v02", "v02")
      assert path == []
    end
  end
end
