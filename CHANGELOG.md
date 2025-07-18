# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2025-01-17

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