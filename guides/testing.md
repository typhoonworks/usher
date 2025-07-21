# Testing

This guide covers how to set up testing for Usher and test invitation workflows in your application.

## Test Setup

### Database Requirements

Usher requires PostgreSQL to run tests. You can either:

1. **Use Docker Compose** (recommended):
   ```bash
   docker-compose up -d
   ```

2. **Install PostgreSQL manually** and ensure it's running on the configured port.

### Test Configuration

Configure Usher for your test environment in `config/test.exs`:

```elixir
# config/test.exs
config :usher,
  repo: MyApp.Repo,
  token_length: 6,  # Shorter tokens for tests
  default_expires_in: {1, :hour},  # Short expiration for tests
  validations: %{
    invitation_usage: %{
      valid_usage_entity_types: [:user, :company, :device],
      valid_usage_actions: [:visited, :registered, :activated]
    }
  }
```

### Test Database Setup

Run the setup command to create and migrate your test database:

```bash
mix test.setup
```

Or manually:

```bash
mix ecto.create
mix ecto.migrate
```

## Using Test Fixtures

Usher provides test fixtures to make testing easier. Import them in your test files:

```elixir
# In your test files
import Usher.TestFixtures

test "user registration with invitation" do
  invitation = invitation_fixture()
  # ... test your registration flow
end
```

### Available Fixtures

```elixir
defmodule MyApp.TestHelpers do
  import Usher.TestFixtures
  
  def setup_invitations do
    %{
      valid_invitation: invitation_fixture(),
      expired_invitation: invitation_fixture(%{
        expires_at: DateTime.add(DateTime.utc_now(), -1, :day)
      }),
      custom_invitation: invitation_fixture(%{
        token: "test-token-123",
        expires_at: DateTime.add(DateTime.utc_now(), 7, :day)
      })
    }
  end
end
```

## Testing Utilities
Here are some utilities to help with testing Usher functionality:

### Custom Test Helpers

```elixir
defmodule MyApp.InvitationTestHelpers do
  import Usher.TestFixtures
  
  def create_expired_invitation(attrs \\ %{}) do
    default_attrs = %{expires_at: DateTime.add(DateTime.utc_now(), -1, :day)}
    invitation_fixture(Map.merge(default_attrs, attrs))
  end
  
  def create_valid_invitation(attrs \\ %{}) do
    default_attrs = %{expires_at: DateTime.add(DateTime.utc_now(), 7, :day)}
    invitation_fixture(Map.merge(default_attrs, attrs))
  end
  
  def invitation_url_for(invitation, base_url \\ "http://localhost:4000/signup") do
    Usher.invitation_url(invitation.token, base_url)
  end
end
```