# Invitation Usage Tracking

This guide explains how to use Usher's invitation tracking features to monitor entity interactions with invitation links and gather usage statistics.

With Usher, you can track any domain entity's usage of invitation links, such as users, companies, devices, etc.

## A note about tracking

Most countries around the world have privacy laws that regulate user tracking. Please ensure you comply with all relevant regulations (e.g., GDPR, CCPA) when implementing tracking features in your application. **Usher does not handle compliance for you**.

We encourage you to only track what is necessary, to be transparent with your users about what you are tracking and why, and to anonymize tracking where possible.

## Configuration

First, configure the valid entity types and actions in your `config/config.exs`:

```elixir
config :usher,
  repo: MyApp.Repo,
  validations: %{
    invitation_usage: %{
      # Required for entity tracking
      valid_usage_entity_types: [:user, :company, :device],
      valid_usage_actions: [:visited, :registered, :activated]
    }
  }
```

## Entity Tracking

### Track Invitation Usage

Track when entities interact with your invitation links:

```elixir
# Track with invitation struct
{:ok, usage} = Usher.track_invitation_usage(
  invitation,
  :user,                   # entity type
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
    # Entity type not in valid_usage_entity_types config

  {:error, :invalid_action} ->
    # Action not in valid_usage_actions config

  {:error, %Ecto.Changeset{}} ->
    # Database constraint violation (e.g., duplicate tracking)
end
```
