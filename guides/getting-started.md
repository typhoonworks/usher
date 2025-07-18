# Getting Started

This guide will walk you through setting up Usher and creating your first invitations.

## Prerequisites

Before you begin, make sure you have:
- Completed the [Installation](installation.md) steps
- A running Ecto-based Elixir application
- PostgreSQL database set up and migrated

## Configuration

Configure Usher in your `config/config.exs` file.

Here's a basic example, to get you started:

```elixir
# Only the required configuration options are shown below.
config :usher,
  repo: MyApp.Repo,
  valid_entity_types: [:user, :company],
  valid_actions: [:visited, :registered, :activated]
```

You can find details about configuration options in the [Configuration Guide](configuration.md).

## Basic Usage

### Creating Your First Invitation

```elixir
# Create with default settings (7-day expiration)
{:ok, invitation} = Usher.create_invitation()

# The invitation will have a generated token and expires_at timestamp
IO.inspect(invitation.token)      # => "a1b2c3d4e5f6g7h8"
IO.inspect(invitation.expires_at) # => ~U[2024-01-15 10:30:00Z]
```

### Creating Invitations with Custom Settings

```elixir
# Create with custom expiration (30 days from now)
{:ok, invitation} = Usher.create_invitation(%{
  expires_at: DateTime.add(DateTime.utc_now(), 30, :day)
})

# Create with custom token
{:ok, invitation} = Usher.create_invitation(%{
  token: "my-custom-token"
})

# Create with both custom token and expiration
{:ok, invitation} = Usher.create_invitation(%{
  token: "welcome-2024",
  expires_at: DateTime.add(DateTime.utc_now(), 14, :day)
})
```

### Validating Invitations

When users visit your application with an invitation token, validate it:

```elixir
case Usher.validate_invitation_token("a1b2c3d4e5f6g7h8") do
  {:ok, invitation} -> 
    # Valid invitation - proceed with your logic
    IO.puts("Welcome! Invitation expires: #{invitation.expires_at}")
    
  {:error, :invalid_token} -> 
    # Token doesn't exist in database
    IO.puts("Invalid invitation token")
    
  {:error, :invitation_expired} -> 
    # Token exists but has expired
    IO.puts("This invitation has expired")
end
```

### Tracking Usage

When a user successfully uses an invitation (e.g., completes registration), track the usage:

```elixir
# Increment the usage counter
{:ok, updated_invitation} = Usher.increment_joined_count(invitation)
IO.puts("#{updated_invitation.joined_count} users have used this invitation")
```

### Building Invitation URLs

Create shareable URLs with invitation tokens:

```elixir
# Basic URL
url = Usher.invitation_url("a1b2c3d4e5f6g7h8", "https://myapp.com/signup")
# => "https://myapp.com/signup?invitation_token=a1b2c3d4e5f6g7h8"

# The function handles existing query parameters
url = Usher.invitation_url("a1b2c3d4e5f6g7h8", "https://myapp.com/signup?ref=email")
# => "https://myapp.com/signup?ref=email&invitation_token=a1b2c3d4e5f6g7h8"
```

## Complete Example

Here's a complete example showing a typical invitation workflow:

```elixir
defmodule MyApp.InvitationWorkflow do
  def create_and_send_invitation(email) do
    # Create invitation
    {:ok, invitation} = Usher.create_invitation(%{
      expires_at: DateTime.add(DateTime.utc_now(), 14, :day)
    })
    
    # Build invitation URL
    invite_url = Usher.invitation_url(invitation.token, "https://myapp.com/signup")
    
    # Send email (using your preferred email library)
    MyApp.Mailer.send_invitation_email(email, invite_url)
    
    {:ok, invitation}
  end
  
  def handle_signup(params) do
    case params["invitation_token"] do
      token when is_binary(token) ->
        case Usher.validate_invitation_token(token) do
          {:ok, invitation} ->
            # Proceed with user registration
            with {:ok, user} <- create_user(params),
                 {:ok, _} <- Usher.increment_joined_count(invitation) do
              {:ok, user}
            end
            
          {:error, reason} ->
            {:error, "Invalid invitation: #{reason}"}
        end
        
      _ ->
        {:error, "Invitation token required"}
    end
  end
  
  defp create_user(params) do
    # Your user creation logic here
    {:ok, %{id: 1, email: params["email"]}}
  end
end
```

## Next Steps

- Learn how to track invitation usage in more detail in the [Usage Tracking Guide](invitation-usage-tracking.md)
- Learn about [Configuration](configuration.md) options for advanced setups
- Explore [Advanced Usage](advanced-usage.md) patterns like cleanup and complex validation
- See [Phoenix Integration](phoenix-integration.md) for framework-specific examples
- Set up [Testing](testing.md) for your invitation workflows