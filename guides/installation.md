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

### 1. Configuring the JSON library

Ecto requires a JSON library for encoding and decoding JSON data. While this is optional, Usher requires it due to custom Ecto types.

**If you're on Elixir 1.18 or later**, you can use the built-in `Elixir.JSON` module, like so:
```elixir
config :postgrex, json_library: Elixir.JSON
```

Otherwise, you can use `Jason` as your JSON library. Add it to your dependencies:

```elixir
def deps do
  [
    {:usher, "~> 0.1.0"},
    {:jason, "~> 1.4"}
  ]
end
```

> ⚠️ if you change the `json_library` configuration, make sure to recompile the Postgrex adapter. [Otherwise your change won't be picked up](https://hexdocs.pm/ecto/Ecto.Schema.html#module-the-map-type):
```bash
mix deps.clean --build postgrex
```

### 2. Generate Migration

Create a new migration file:

```bash
mix ecto.gen.migration install_usher_tables
```

### 3. Add Migration Content

Add the Usher schema to your migration file.

**For first-time installations:**

```elixir
defmodule MyApp.Repo.Migrations.InstallUsherTables do
  use Ecto.Migration

  def up do
    Usher.Migration.migrate_to_version("v04")  # Latest version
  end

  def down do
    Usher.Migration.migrate_to_version("v01")  # First version
  end
end
```

**For existing installations upgrading to a new version:**

Check the [CHANGELOG.md](../CHANGELOG.md) for migration instructions specific to your current version. Each release includes detailed migration guides with the required database changes.

### 4. Run Migration

Execute the migration:

```bash
mix ecto.migrate
```

This will create the necessary tables for storing invitations and tracking their usage.

> ℹ️ Pass in the `Usher.Migration.latest_version/0` value to `Usher.Migration.migrate_to_version/1` to apply only the necessary migrations.

## Next Steps

After installation, you'll need to configure Usher for your application. See the [Getting Started Guide](getting-started.md) for configuration and basic usage examples.