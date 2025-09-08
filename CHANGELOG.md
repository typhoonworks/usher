# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Migration Guide

**Major Migration Update:**

⚠️ This version changes migration versions from strings (e.g. "v01", "v02") to integers (e.g. 1, 2) ⚠️

While this simplifies the migration system of Usher, it requires a small change in your migration files.

Currently, your migration files will contain calls to `Usher.Migration.migrate_to_version/1` with string versions:

```elixir
Usher.Migration.migrate_to_version("v03")
```

You will need to change the migration version argument to an integer:

```elixir
Usher.Migration.migrate_to_version(3)
```

If you are using an editor like VSCode, you can use the "Find and Replace" feature with regex enabled. Perform a regex search for `migrate_to_version\("v0(\d)"\)` and replace with `migrate_to_version($1)`.

Alternatively, you can run the following from within your `migrations` directory:

```bash
find . -type f -name "*.exs" -print0 | xargs -0 sed -E -i.bak 's/migrate_to_version\("v0([0-9])"\)/migrate_to_version(\1)/g' && find . -type f -name "*.bak" -delete
```

**Database Migration Required:**

For existing installations, create a new migration to add custom attributes support:

```bash
mix ecto.gen.migration upgrade_usher_tables_v05
```

```elixir
defmodule MyApp.Repo.Migrations.UpgradeUsherTablesV05 do
  use Ecto.Migration

  def up do
    Usher.Migration.migrate_to_version(5)
  end

  def down do
    Usher.Migration.migrate_to_version(4)
  end
end
```

This migration adds a `custom_attributes` field to the invitations table for storing additional invitation metadata.

### Added

- **Custom Attributes Support**: Added `custom_attributes` field to `Usher.Invitation` schema for storing custom attributes for use with the invitation (defaults to `:map` type)
- **Configurable Custom Attributes Schema**: Added ability to configure embedded schema for custom attributes field via `config :usher, schemas: %{invitation: %{custom_attributes_type: YourSchema}}`
- Database migration `Usher.Migrations.V05` to add the `custom_attributes` column
- New test environment `test_custom_attributes_embedded_schema` for testing embedded schema configuration
- **Invitation token signatures**:
  - New `Usher.Token.Signature` module to sign and verify user-supplied tokens using HMAC-SHA256
  - New `Usher.create_invitation_with_signed_token/2` to create an invitation and return a signed presentation token
  - New `Usher.validate_secure_invitation_token/2` to verify the signature and validate the invitation in one step
  - New `Usher.signed_invitation_url/3` to build URLs containing both the `invitation_token` and its signature (`s` query param)
- New configuration option: `config :usher, signing_secret: "..."` to enable token signing/verification

### Changed

- Testing infrastructure with separate test environment for compile-time config values.
- Strengthened randomly generated invitation tokens. Switched to unbiased, cryptographically secure base62 token generation (avoids modulo bias)

Note: In v0.6.0, the migration system will be updated to use integers for versioning (e.g. 1, 2, 3, etc.) instead of strings (e.g. "v01", "v02", etc.). This will simplify migration management and allow for easier version comparisons in the `Usher.Migration` module.

## [0.4.0] - 2025-08-02

### Migration Guide

**Database Migration Required:**

For existing installations, create a new migration to enable expiration extension features:

```bash
mix ecto.gen.migration upgrade_usher_tables_v04
```

```elixir
defmodule MyApp.Repo.Migrations.UpgradeUsherTablesV04 do
  use Ecto.Migration

  def up do
    Usher.Migration.migrate_to_version("v04")
  end

  def down do
    Usher.Migration.migrate_to_version("v03")
  end
end
```

This migration makes the `expires_at` column nullable to support never-expiring invitations.

Additionally, you will have to go back to any Usher migrations using the `Usher.Migration.migrate_to_latest/1` function and change it to `Usher.Migration.migrate_to_version("v02")`, as the `Usher.Migration.migrate_to_latest/1` function has been removed:

```elixir
defmodule MyApp.Repo.Migrations.UpgradeUsherTablesV02 do
  use Ecto.Migration

  def change do
    # Previously:
    # Usher.Migration.migrate_to_latest()
    Usher.Migration.migrate_to_version("v02")
  end
end
```

### Added

- **Invitation Expiration/Extension System**: Added ability to extend, set, or remove expiration dates from invitations
- New API functions:
  - `Usher.extend_invitation_expiration/2` - Extend existing invitation expiration by given duration
  - `Usher.set_invitation_expiration/2` - Set specific expiration DateTime for an invitation
  - `Usher.remove_invitation_expiration/1` - Remove expiration to make an invitation never expire
- Database migration `Usher.Migrations.V04` to make `expires_at` column nullable

### Changed

- `Usher.Invitation` schema now allows `nil` for `expires_at` field to support never-expiring invitations
- `Usher.validate_invitation_token/1` now treats invitations with `nil` `expires_at` as valid (never expire)

### Fixed

- Migration "v03" now sets migration to version to "v02" when rolling back. Previously, it did not set the version correctly.
- `Usher.Migration` functions were not executing `down/1` functions correctly. This has been fixed to ensure proper rollback behavior.

### Removed

- Removed deprecated `Usher.Migration.migrate_to_latest/1` function. Use `Usher.Migration.migrate_to_version/1` instead.

## [0.3.1] - 2025-07-22

### Fixed

- Fixed a bug with the `%{invitation: %{name_required: boolean()}` configuration option not being correctly recognized when set to `false`. The `Usher.Config.name_required?/0` function now correctly returns `false` when the configuration is set to not require names for invitations.

## [0.3.0] - 2025-07-21

### Migration Guide

**1. Dropping `table_name` Configuration:**

The `table_name` configuration option has been removed. Usher now uses a fixed table name `usher_invitations` for the invitations table.

If you were using a custom table name, you will need to rename the table to `usher_invitations`. You can do this as follows, by creating a new migration:

```bash
mix ecto.gen.migration rename_usher_invitations_table
```

You might be wondering "if this is a breaking change, wouldn't the rename fail when I run all the migrations again (such as in a dev environment with `mix ecto.reset`)?". You won't encounter this issue if you check to see whether the `usher_invitations` table already exists before attempting to rename it. Here's an example migration that does this:

```elixir
defmodule MyApp.Repo.Migrations.RenameUsherInvitationsTable do
  use Ecto.Migration

  def up do
    # Check if usher_invitations table exists using raw SQL
    result = repo().query!("SELECT to_regclass('usher_invitations');")
    table_exists? =
      case result.rows do
        [[value]] when not is_nil(value) -> true
        _ -> false
      end

    if not table_exists? do
      rename table(:your_invitations_table_name), to: table(:usher_invitations)
    end
  end

  def down do
    rename table(:usher_invitations), to: table(:your_invitations_table_name)
  end
end
```

Alternatively, you can delete the old Usher migrations and keep the latest migration that calls `Usher.Migration.migrate_to_version("v03")`, which will create all the necessary tables.

**2. New Database Migration and Required Configuration:**

For existing installations, create a new migration:

```bash
mix ecto.gen.migration upgrade_usher_tables_v03
```

Use the new migration helper:

```elixir
defmodule MyApp.Repo.Migrations.UpgradeUsherTablesV03 do
  use Ecto.Migration

  def change do
    Usher.Migration.migrate_to_version("v03")
  end
end
```

Then, update your configuration to include the new `valid_usage_entity_types` and `valid_usage_actions` options, under the `validations` key:

```elixir
config :usher, Usher.Config,
  validations: %{
    invitation_usage: %{
      valid_usage_entity_types: [:user, :organization],
      valid_usage_actions: [:visited, :registered]
    }
  }
```

_Note: the new `valid_usage_entity_types` and `valid_usage_actions` options are **required**_

See the [configuration guide](guides/configuration.md) for more details.

> ⚠️ There was a change in the migration system. The `migrate_to_latest/1` function is deprecated and will be removed in the next major release. Use `migrate_to_version/1` instead.

**3. Removed `Usher.increment_joined_count/1` function:**

The `Usher.increment_joined_count/1` function has been removed. Use the new `Usher.track_invitation_usage/5` function to track invitation usage instead:

```elixir
{:ok, _} = Usher.track_invitation_usage(invitation, :user, user.id, :registered, metadata)
```

### Added

- **Invitation Usage Tracking System**: Introduced mapping between invitations and entity interactions
- New schema `Usher.InvitationUsage` for tracking entity interactions with invitations. With this schema, you can now track when an entity uses an invitation, including the entity type, action taken, and timestamp.
- New query module `Usher.Invitations.InvitationUsageQuery` for building invitation usage queries
- Database migration `Usher.Migrations.V03` to create the invitation usage table
- Custom type `Usher.Types.Atom` for handling atoms as strings in database schemas
- New API functions:
  - `Usher.track_invitation_usage/5` - Track when an entity uses an invitation
  - `Usher.list_invitation_usages/2` - List all usage records for an invitation
  - `Usher.list_invitation_usages_by_unique_entity/2` - Get unique entities that have used an invitation
  - `Usher.entity_used_invitation?/4` - Check if an entity has used an invitation
- Configuration options for entity tracking:
  - `valid_usage_entity_types` - Define allowed entity types
  - `valid_usage_actions` - Define allowed actions
- Split the README into individual guides, now also included in the hexdocs as "guides".
- Added `jason` as a dependency because it's required for custom Ecto types (used for allowing atoms from strings in the schema definition).

### Changed

- **`Usher.Migration.migrate_to_latest/1` is deprecated; use `Usher.Migration.migrate_to_version/1` instead.** `Usher.Migration.migrate_to_latest/1` will be removed in the next major release. Please check the [installation guide](guides/installation.md) for new migration instructions.
- Updated `Usher.Invitation` schema with new associations to usage tracking schema.
- Added new config options to `Usher.Config` for specifying valid entity types and actions that can be tracked with the invitation usage system.

### Removed

- Removed `Usher.increment_joined_count/1` function. Use `Usher.track_invitation_usage/5` instead to track invitation usage.
- Removed `table_name` configuration option. Usher now uses a fixed table name `usher_invitations` for the invitations table.

## [0.2.0] - 2025-07-18

### Added

- Optional name field for invitations with configurable validation
- Versioned migration system for safe database schema upgrades
- Extensible validation configuration: `validations: %{invitation: %{name_required: true}}` (defaults to requiring names)
- Per-function validation options to override configuration defaults via `require_name` option
- Comprehensive development setup documentation in README
- Database migration tests and name validation tests
- CHANGELOG.md following Keep a Changelog format

### Changed

- Migration system now uses `migrate_to_latest/1` instead of `create_usher_invitations_table/1`
- Consolidated multiple function arities into single functions with default parameters
- Updated README with complete development setup guide
- Enhanced configuration examples with extensible validation structure
- Error atom changed from `:expired` to `:invitation_expired` for consistency

### Removed

- `create_usher_invitations_table/1` function (replaced by versioned migrations)
- `drop_usher_invitations_table/1` function (replaced by versioned migrations)

### Migration Guide

For existing installations, create a new migration:

```bash
mix ecto.gen.migration upgrade_usher_tables
```

Use the new migration helper:

```elixir
defmodule YourApp.Repo.Migrations.UpgradeUsherTables do
  use Ecto.Migration
  import Usher.Migration

  def change do
    migrate_to_latest()
  end
end
```

This will automatically detect your current schema version and apply only the necessary migrations.

## [0.1.2] - 2025-01-15

### Added

- First package to be released on hex.pm! 🎉
- Token generation using cryptographic functions
- Framework-agnostic invitation link management
- Configurable token length and expiration periods
- PostgreSQL support with Ecto integration
- Basic invitation validation and tracking

### Fixed

- Fix project name for hex publish
