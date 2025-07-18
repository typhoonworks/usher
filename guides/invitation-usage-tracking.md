# Invitation Usage Tracking

This guide explains how to use Usher's invitation tracking features to monitor entity interactions with invitation links and gather usage statistics.

With Usher, you can track any domain entity's usage of invitation links, such as users, companies, devices, etc.

## Overview

Usher provides two levels of invitation tracking:
1. **Basic tracking** - Simple joined count for backward compatibility
2. **Entity tracking** - Detailed tracking of different entity types and their actions

## Configuration

First, configure the valid entity types and actions in your `config/config.exs`:

```elixir
config :usher,
  repo: MyApp.Repo,
  # Required for entity tracking
  valid_entity_types: [:user, :company, :device, :organization],
  valid_actions: [:visited, :registered, :activated, :converted]
```

## Database Setup

Add the invitation tracking tables to your database:

```elixir
# Create a migration file
defmodule MyApp.Repo.Migrations.CreateUsherTables do
  use Ecto.Migration
  import Usher.Migration

  def change do
    create_usher_invitations_table()
    create_usher_invitation_usages_table()
  end
end
```

## Entity Tracking

### Track Invitation Usage

Track when entities interact with your invitation links:

```elixir
# Track with invitation struct
{:ok, usage} = Usher.track_invitation_usage(
  invitation,
  :user,                    # entity type
  "user_123",              # entity ID
  :registered,             # action
  %{                       # optional metadata
    plan: "premium",
    ip: "192.168.1.1",
    user_agent: "Mozilla/5.0...",
    campaign: "summer_2024"
  }
)

# Track with token string
{:ok, usage} = Usher.track_invitation_usage(
  "abc123token",
  :company,
  "company_456",
  :visited,
  %{referrer: "google.com"}
)
```

### Common Tracking Patterns

**Track page visits:**
```elixir
# When someone clicks the invitation link
Usher.track_invitation_usage(token, :user, user_id, :visited, %{
  ip: request_ip,
  user_agent: user_agent,
  timestamp: DateTime.utc_now()
})
```

**Track registrations:**
```elixir
# When user completes registration
Usher.track_invitation_usage(invitation, :user, new_user.id, :registered, %{
  plan: selected_plan,
  signup_method: "email"
})
```

**Track activations:**
```elixir
# When user activates their account
Usher.track_invitation_usage(invitation, :user, user.id, :activated, %{
  activation_method: "email_confirmation"
})
```

## Getting Usage Statistics

### List All Usage Records

```elixir
# Get all usage records for an invitation
usages = Usher.list_invitation_usages(invitation)

# Filter by entity type
user_usages = Usher.list_invitation_usages(invitation, entity_type: :user)

# Filter by action
registrations = Usher.list_invitation_usages(invitation, action: :registered)

# Multiple filters with pagination
recent_visits = Usher.list_invitation_usages(invitation, 
  entity_type: :user,
  action: :visited,
  limit: 10
)
```

### Analyze Unique Entities

```elixir
# Get unique entities that used the invitation
entities = Usher.list_invitation_usages_by_unique_entity(invitation)
# Returns: [{"user_123", [usage_records...]}, {"company_456", [usage_records...]}]

# Filter for specific actions
registered_entities = Usher.list_invitation_usages_by_unique_entity(
  invitation, 
  action: :registered
)
```

### Check Individual Entity Usage

```elixir
# Check if a specific entity used the invitation
has_used = Usher.entity_used_invitation?(invitation, :user, "user_123")

# Check for specific action
has_registered = Usher.entity_used_invitation?(invitation, :user, "user_123", :registered)
```

## Analytics Examples

### Conversion Funnel Analysis

```elixir
defmodule MyApp.InvitationAnalytics do
  def conversion_funnel(invitation) do
    visits = Usher.list_invitation_usages(invitation, action: :visited)
    registrations = Usher.list_invitation_usages(invitation, action: :registered)
    activations = Usher.list_invitation_usages(invitation, action: :activated)
    
    %{
      visits: length(visits),
      registrations: length(registrations),
      activations: length(activations),
      visit_to_registration_rate: length(registrations) / max(length(visits), 1),
      registration_to_activation_rate: length(activations) / max(length(registrations), 1)
    }
  end
end
```

### Entity Type Breakdown

```elixir
defmodule MyApp.InvitationAnalytics do
  def entity_breakdown(invitation) do
    invitation
    |> Usher.list_invitation_usages()
    |> Enum.group_by(& &1.entity_type)
    |> Enum.map(fn {entity_type, usages} ->
      {entity_type, length(usages)}
    end)
    |> Enum.into(%{})
  end
end
```

### Metadata Analysis

```elixir
defmodule MyApp.InvitationAnalytics do
  def referrer_sources(invitation) do
    invitation
    |> Usher.list_invitation_usages(action: :visited)
    |> Enum.map(& get_in(&1.metadata, ["referrer"]))
    |> Enum.filter(& &1)
    |> Enum.frequencies()
  end
  
  def plan_preferences(invitation) do
    invitation
    |> Usher.list_invitation_usages(action: :registered)
    |> Enum.map(& get_in(&1.metadata, ["plan"]))
    |> Enum.filter(& &1)
    |> Enum.frequencies()
  end
end
```

## Legacy Tracking

For simple use cases, you can still use the basic joined count:

```elixir
# Increment the simple counter
{:ok, updated_invitation} = Usher.increment_joined_count(invitation)

# Access the count
count = invitation.joined_count
```

## Error Handling

Common error scenarios and handling:

```elixir
case Usher.track_invitation_usage(token, :user, "123", :registered) do
  {:ok, usage} -> 
    # Success
    usage
    
  {:error, :invalid_token} -> 
    # Token doesn't exist
    
  {:error, :invitation_expired} -> 
    # Invitation has expired
    
  {:error, :invalid_entity_type} -> 
    # Entity type not in valid_entity_types config
    
  {:error, :invalid_action} -> 
    # Action not in valid_actions config
    
  {:error, %Ecto.Changeset{}} -> 
    # Database constraint violation (e.g., duplicate tracking)
end
```

## Best Practices

1. **Use meaningful entity types** - Choose types that match your business model
2. **Track the full journey** - Record visits, registrations, and activations
3. **Include relevant metadata** - Store context that helps with analysis
4. **Handle duplicates gracefully** - The system prevents duplicate tracking automatically
5. **Validate tokens before tracking** - Always check if invitation is valid and not expired
6. **Use filtering for large datasets** - Apply entity_type and action filters for performance

## Performance Considerations

- Use database indexes on frequently queried fields
- Consider pagination for large usage datasets
- Cache frequently accessed statistics
- Use database-level aggregations for complex analytics

This tracking system provides comprehensive insights into how your invitation links are being used, helping you optimize your conversion funnels and understand user behavior patterns.