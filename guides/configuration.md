# Configuration

This guide covers all configuration options available in Usher and how to set them up for different scenarios.

## Basic Configuration

Configure Usher in your `config/config.exs` file:

```elixir
config :usher,
  repo: MyApp.Repo,
  token_length: 16,
  default_expires_in: {7, :day},
  validations: %{
    invitation: %{
      name_required: true
    },
    invitation_usage: %{
      valid_usage_entity_types: [:user, :company, :device],
      valid_usage_actions: [:visited, :registered, :activated]
    }
  }
```

## Configuration Options

| Option                | Type    | Default     | Required | Description                                   |
| --------------------- | ------- | ----------- | -------- | --------------------------------------------- |
| `:repo`               | module  | N/A         | **Yes**  | Your Ecto repository module                   |
| `:token_length`       | integer | `16`        | No       | Length of generated invitation tokens         |
| `:default_expires_in` | tuple   | `{7, :day}` | No       | Default expiration period for new invitations |
| `:validations`        | map     | `%{}`       | No       | Map defining validation rules for invitations |
| `:schemas`            | map     | `%{}`       | No       | Map defining custom schema configurations     |

### Validations

You can define validation rules for invitations using the `:validations` option. This allows you to enforce (or make optional) certain rules (available as features in Usher) such as requiring a name for invitations.

The `:validations` option accepts a map where keys are schema types (like `:invitation`) and values are maps of validation rules. For example:

```elixir
config :usher,
  validations: %{
    invitation: %{
      name_required: false
    },
    invitation_usage: %{
      valid_usage_entity_types: [:user, :company, :device],
      valid_usage_actions: [:visited, :registered, :activated]
    }
  }
```

The available options for `:invitation` are:

| Option           | Type    | Default | Required | Description                             |
| ---------------- | ------- | ------- | -------- | --------------------------------------- |
| `:name_required` | boolean | `true`  | No       | Whether the invitation must have a name |

The available options for `:invitation_usage` are:

| Option                      | Type | Default | Required | Description                                                    |
| --------------------------- | ---- | ------- | -------- | -------------------------------------------------------------- |
| `:valid_usage_entity_types` | list | `nil`   | Yes      | List of atoms defining allowed entity types for usage tracking |
| `:valid_usage_actions`      | list | `nil`   | Yes      | List of atoms defining allowed actions for usage tracking      |

### Schemas

You can customize the schema behavior for various parts of Usher using the `:schemas` option.

The `:schemas` option accepts a map where keys are schema names (like `:invitation`) and values are maps of schema configurations. For example:

```elixir
config :usher,
  schemas: %{
    invitation: %{
      custom_attributes_embedded_schema: MyApp.InvitationAttributes
    }
  }
```

The available options for `:invitation` schemas are:

| Option                               | Type   | Default | Required | Description                                        |
| ------------------------------------ | ------ | ------- | -------- | -------------------------------------------------- |
| `:custom_attributes_embedded_schema` | module | `nil`   | No       | Embedded schema module for custom_attributes field |

## Custom Attributes Configuration

Usher supports storing custom attributes with invitations through the `custom_attributes` field. By default, this field uses the `:map` type, but you can use an embedded schema if you'd like.

### Using Map Type (Default)

The simplest approach is to use the default `:map` type:

```elixir
{:ok, invitation} = Usher.create_invitation(%{
  name: "Join our team",
  custom_attributes: %{
    "role" => "developer",
    "department" => "engineering",
    "tags" => ["backend", "elixir"]
  }
})

# Access after validation
case Usher.validate_invitation_token(token) do
  {:ok, invitation} ->
    role = invitation.custom_attributes["role"]
    # Use role for user creation or other business logic
  {:error, reason} ->
    # Handle error
end
```

### Using Embedded Schema

For better type safety and validation, configure an embedded schema:

```elixir
# In config/config.exs
config :usher,
  repo: MyApp.Repo,
  # Other configuration...
  schemas: %{
    invitation: %{
      custom_attributes_embedded_schema: MyApp.InvitationAttributes
    }
  }
```

Then define your embedded schema:

```elixir
defmodule MyApp.InvitationAttributes do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field(:role, Ecto.Enum, values: [:admin, :manager, :user])
    field(:department, :string)
    field(:tags, {:array, :string})
    field(:welcome_message, :string)
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:role, :department, :tags, :welcome_message])
    |> validate_required([:role])
    |> validate_inclusion(:role, [:admin, :manager, :user])
  end
end
```

With the embedded schema configured, you can use it like this:

```elixir
{:ok, invitation} = Usher.create_invitation(%{
  name: "Join our team",
  custom_attributes: %{
    role: :developer,
    department: "engineering",
    tags: ["backend", "elixir"],
    welcome_message: "Welcome to our development team!"
  }
})

# Access typed fields after validation
case Usher.validate_invitation_token(token) do
  {:ok, invitation} ->
    role = invitation.custom_attributes.role
    department = invitation.custom_attributes.department
    # Use role for user creation or other business logic
  {:error, reason} ->
    # Handle error
end
```

## Entity Usage Tracking Configuration

For usage tracking of invitation interactions, you must configure entity types and actions:

```elixir
config :usher,
  repo: MyApp.Repo,
  # Basic configuration
  token_length: 16,
  default_expires_in: {7, :day},
  # Entity tracking configuration
  validations: %{
    invitation_usage: %{
      valid_usage_entity_types: [:user, :company, :device],
      valid_usage_actions: [:visited, :registered, :activated]
    }
  }
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
