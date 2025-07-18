# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2025-07-20

### Migration Guide
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

> ⚠️ There was a change in the migration system. The `migrate_to_latest/1` function is deprecated and will be removed in the next major release. Use `migrate_to_version/1` instead.

### Added
- **Invitation Usage Tracking System**: Introduced mapping between invitations and entity interactions
- New schema `Usher.InvitationUsage` for tracking entity interactions with invitations. With this schema,
  you can now track when an entity uses an invitation, including the entity type, action taken, and timestamp.
- New query module `Usher.Invitations.InvitationUsageQuery` for building invitation usage queries
- Database migration `Usher.Migrations.V03` to create the invitation usage table
- Custom type `Usher.Types.Atom` for handling atoms as strings in database schemas
- New API functions:
  - `Usher.track_invitation_usage/5` - Track when an entity uses an invitation
  - `Usher.list_invitation_usages/2` - List all usage records for an invitation
  - `Usher.list_invitation_usages_by_unique_entity/2` - Get unique entities that have used an invitation
  - `Usher.entity_used_invitation?/4` - Check if an entity has used an invitation
- Configuration options for entity tracking:
  - `valid_entity_types` - Define allowed entity types
  - `valid_actions` - Define allowed actions
- Split the README into individual guides, now also included in the hexdocs as "guides".
- Added `jason` as a dependency because it's required for custom Ecto types (used for allowing atoms from strings in the schema definition).

### Changed
- **`Usher.Migration.migrate_to_latest/1` is deprecated; use `Usher.Migration.migrate_to_version/1` instead.** `Usher.Migration.migrate_to_latest/1` will be removed in the next major release. Please check the [installation guide](guides/installation.md) for new migration instructions.
- Moved V03 migration to separate module for better organization
- Enhanced migration system to track version state via database comments
- Updated `Usher.Invitation` schema with new associations to usage tracking
- Enhanced `Usher.Config` with validation for new entity tracking features

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