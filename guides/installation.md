# Installation

## Requirements

Usher requires:
- Elixir 1.14 or later
- OTP 25 or later
- PostgreSQL

> **Note**: Usher may work with earlier versions of Elixir and OTP, but it wasn't tested against them.

## Adding Usher to Your Project

Add `usher` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:usher, "~> 0.1.0"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Database Setup

Usher requires database tables to store invitation data. You'll need to create and run a migration to set up these tables.

### 1. Generate Migration

Create a new migration file:

```bash
mix ecto.gen.migration install_usher_tables
```

### 2. Add Migration Content

Add the Usher schema to your migration file:

```elixir
defmodule MyApp.Repo.Migrations.InstallUsherTables do
  use Ecto.Migration

  def change do
    Usher.Migration.migrate_to_version("v03")
  end
end
```

### 3. Run Migration

Execute the migration:

```bash
mix ecto.migrate
```

This will create the necessary tables for storing invitations and tracking their usage.

> ℹ️ Pass in the `Usher.Migration.latest_version/0` value to `Usher.Migration.migrate_to_version/1` to apply only the necessary migrations.

## Next Steps

After installation, you'll need to configure Usher for your application. See the [Getting Started Guide](getting-started.md) for configuration and basic usage examples.