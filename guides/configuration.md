# Configuration

This guide covers all configuration options available in Usher and how to set them up for different scenarios.

## Basic Configuration

Configure Usher in your `config/config.exs` file:

```elixir
config :usher,
  repo: MyApp.Repo,
  token_length: 16,
  default_expires_in: {7, :day},
  table_name: "usher_invitations",
  validations: %{
    invitation: %{
      name_required: true
    }
  }
```

## Configuration Options

| Option | Type | Default | Required | Description |
|--------|------|---------|----------|-------------|
| `:repo` | module | N/A | **Yes** | Your Ecto repository module |
| `:token_length` | integer | `16` | No | Length of generated invitation tokens |
| `:default_expires_in` | tuple | `{7, :day}` | No | Default expiration period for new invitations |
| `:table_name` | string | `"usher_invitations"` | No | Database table name for invitations |
| `:valid_entity_types` | list | `[]` | No | List of atoms defining allowed entity types for usage tracking |
| `:valid_actions` | list | `[]` | No | List of atoms defining allowed actions for usage tracking |
| `:validations` | map | `%{}` | No | Map defining validation rules for invitations |

### Validations
You can define validation rules for invitations using the `:validations` option. This allows you to enforce (or make optional) certain rules (available as features in Usher) such as requiring a name for invitations.

The `:validations` option accepts a map where keys are schema types (like `:invitation`) and values are maps of validation rules. For example:

```elixir
config :usher,
  validations: %{
    invitation: %{
      name_required: false
    }
  }
```

The full map of available options are as follows:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:name_required` | boolean | `true` | Whether the invitation must have a name |

## Entity Usage Tracking Configuration

For usage tracking of invitation interactions, you must configure entity types and actions:

```elixir
config :usher,
  repo: MyApp.Repo,
  # Basic configuration
  token_length: 16,
  default_expires_in: {7, :day},
  table_name: "usher_invitations",
  # Entity tracking configuration
  valid_entity_types: [:user, :company, :device],
  valid_actions: [:visited, :registered, :activated]
```

### Entity Types

Define what types of entities can interact with invitations. You can use any atoms you'd like, here are some examples:

- `:user` - Individual users
- `:company` - Organizations or companies
- `:device` - Hardware devices or IoT endpoints
- `:team` - Team or group entities
- Any custom atom representing your domain entities

### Actions

Define what actions can be tracked. You can use any atoms you'd like, here are some examples:

- `:visited` - Entity visited the invitation page
- `:registered` - Entity completed registration
- `:activated` - Entity activated their account
- `:downloaded` - Entity downloaded something
- Any custom atom representing actions in your domain

## Time Units

The `:default_expires_in` option accepts tuples with these time units:

- `:second`
- `:minute`
- `:hour`
- `:day`
- `:week`
- `:month`
- `:year`

Examples:
```elixir
# Various time configurations
default_expires_in: {30, :minute}   # 30 minutes
default_expires_in: {2, :hour}      # 2 hours  
default_expires_in: {7, :day}       # 7 days (default)
default_expires_in: {2, :week}      # 2 weeks
default_expires_in: {1, :month}     # 1 month
```

## Runtime Configuration

You can also configure Usher at runtime or override specific values:

```elixir
# Override default expiration for specific invitations
{:ok, invitation} = Usher.create_invitation(%{
  expires_at: DateTime.add(DateTime.utc_now(), 1, :hour)
})

# Use custom token length (though token_length config is for generated tokens)
{:ok, invitation} = Usher.create_invitation(%{
  token: "my-very-long-custom-token-here"
})
```

## Accessing Configuration

You can access the current configuration in your application using the `Usher.Config` module.