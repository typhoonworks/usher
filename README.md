# Usher
<p>
  <a href="https://hex.pm/packages/usher">
    <img alt="Hex Version" src="https://img.shields.io/hexpm/v/usher.svg">
  </a>
  <a href="https://hexdocs.pm/usher">
    <img src="https://img.shields.io/badge/docs-hexdocs-blue" alt="HexDocs">
  </a>
  <a href="https://github.com/typhoonworks/usher/actions">
    <img alt="CI Status" src="https://github.com/typhoonworks/usher/workflows/ci/badge.svg">
  </a>
</p>

Usher is a web framework-agnostic invitation link management library for any Elixir application with Ecto.

>🚧 This library is in its infancy so you should treat all versions as early pre-release versions. We'll make the best effort to give heads up about breaking changes; however we can't guarantee backwards compatibility for every change.

## Current Features
- 🔐 **Token generation** using cryptographic functions
- 🏗️ **Framework agnostic** - works with any Ecto-based application

## What's planned?
- [ ] Auto-cleanup of expired invitations.
- [ ] More advanced usage tracking.
   - [ ] Metadata about those who visited and used the invitation (approx. location, user agent, etc.).
   - [ ] Linking invitation tokens to user accounts (e.g. to track which user registered with which invitation).
- [ ] Invitation expiration after X number of uses (including one-time use links).
- [ ] One-time use invitation links tied to specific email addresses.
- [ ] Descriptions for invitation links so you can provide context for its usage.

## Installation
Add `usher` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:usher, "~> 0.1.0"}
  ]
end
```

Usher requires Elixir 1.14 or later, and OTP 25 or later. It may work with earlier versions, but it wasn't tested against them.

## Setup

### 1. Database Migration
Generate and run the migration to create the invitations table:
```bash
mix ecto.gen.migration create_usher_tables
```

Add the Usher schema to your migration:
```elixir
defmodule MyApp.Repo.Migrations.CreateUsherTables do
  use Ecto.Migration
  import Usher.Migration

  def change do
    migrate_to_latest()
  end
end
```

Run the migration:
```bash
mix ecto.migrate
```

**For existing installations upgrading to a new version:**
```bash
mix ecto.gen.migration upgrade_usher_tables
```

Use the same migration code - `migrate_to_latest()` will automatically detect your current version and apply only the necessary migrations.

### 2. Configuration
Configure Usher in your `config/config.exs`:
```elixir
config :usher,
  repo: MyApp.Repo,
  token_length: 16,
  default_expires_in: {7, :day},
  table_name: "usher_invitations",
  validations: %{
    invitation: %{
      name_required: false
    }
  }
```

All the values above have defaults, which you can find in `Usher.Config`.

## Basic Usage

### Creating Invitations
```elixir
# Create with defaults (7-day expiration, generated token)
{:ok, invitation} = Usher.create_invitation()

# Create with a name
{:ok, invitation} = Usher.create_invitation(%{
  name: "Team Welcome Invitation"
})

# Create with custom expiration
{:ok, invitation} = Usher.create_invitation(%{
  expires_at: DateTime.add(DateTime.utc_now(), 30, :day)
})

# Create with custom token
{:ok, invitation} = Usher.create_invitation(%{
  token: "custom-invite-token"
})

# Create with name requirement (validates that name is provided)
{:ok, invitation} = Usher.create_invitation(%{
  name: "Required Name"
}, require_name: true)
```

### Validating Invitations
```elixir
case Usher.validate_invitation_token("abc123") do
  {:ok, invitation} -> 
    # Valid invitation - proceed with registration
    IO.puts("Welcome! Invitation expires: #{invitation.expires_at}")
    
  {:error, :invalid_token} -> 
    # Token doesn't exist
    IO.puts("Invalid invitation token")
    
  {:error, :invitation_expired} -> 
    # Token exists but expired
    IO.puts("This invitation has expired")
end

```

### Tracking Usage
```elixir
# When a user successfully registers with an invitation
{:ok, updated_invitation} = Usher.increment_joined_count(invitation)
IO.puts("#{updated_invitation.joined_count} users have used this invitation")
```

### Building Invitation URLs
```elixir
# Simple URL
url = Usher.invitation_url("abc123", "https://myapp.com/signup")
# => "https://myapp.com/signup?invitation_token=abc123"
```

### Cleaning Up Expired Invitations
While this feature doesn't exist for the library yet, you can periodically clean up expired invitations using one of the following examples:
```elixir
defmodule MyApp.InvitationCleanup do
  @moduledoc """
  A module for cleaning up expired invitations.
  
  This can be used with a job scheduler like Oban or simply a GenServer
  to periodically remove expired invitations from the database.
  """
  
  @doc """
  Removes expired invitations older than the given number of days.
  
  This is useful if you want to keep recently expired invitations
  for debugging or analytics purposes.
  """
  def cleanup_old_expired_invitations(days_old \\ 30) do
    cutoff_date = DateTime.utc_now() |> DateTime.add(-days_old, :day)
    
    old_expired_invitations = 
      Usher.list_invitations()
      |> Enum.filter(fn invitation ->
        DateTime.compare(invitation.expires_at, cutoff_date) == :lt
      end)
    
    deleted_count = 
      old_expired_invitations
      |> Enum.reduce(0, fn invitation, acc ->
        # Alternatively, you can use your application's repo to
        # `Repo.delete_all/2` expired invitations in bulk.
        case Usher.delete_invitation(invitation) do
          {:ok, _} -> acc + 1
          {:error, _} -> acc
        end
      end)
    
    deleted_count
  end
end
```

You can then use this module in various ways:
**With Oban (easiest):**
```elixir
defmodule MyApp.Workers.InvitationCleanupWorker do
  @moduledoc """
  A worker that periodically cleans up old expired invitations.

  This worker can be scheduled to run periodically with Oban Cron.
  """
  use Oban.Worker, queue: :cleanup

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    deleted_count = MyApp.InvitationCleanup.cleanup_old_expired_invitations(7)

    {:ok, deleted_count}
  end
end
```

**With a GenServer:**
```elixir
defmodule MyApp.InvitationCleanupCron do
  @moduledoc """
  A GenServer that periodically cleans up expired invitations.
  
  Runs cleanup tasks at configurable intervals and can be
  added to your application's supervision tree.
  """
  use GenServer
  
  require Logger

  # Default cleanup interval: 24 hours
  @default_cleanup_interval_ms 24 * 60 * 60 * 1000
  @default_days_old 7

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @impl GenServer
  def init(opts) do
    cleanup_interval = Keyword.get(opts, :cleanup_interval_ms, @default_cleanup_interval_ms)
    days_old = Keyword.get(opts, :days_old, @default_days_old)

    schedule_cleanup(cleanup_interval)
    
    state = %{
      cleanup_interval: cleanup_interval,
      days_old: days_old,
      last_cleanup: nil
    }
    
    Logger.info("InvitationCleanupCron started with #{cleanup_interval}ms interval")
    {:ok, state}
  end
  
  @impl GenServer
  def handle_info(:cleanup, state) do
    deleted_count = MyApp.InvitationCleanup.cleanup_old_expired_invitations(state.days_old)
    
    new_state = %{
      state | 
      last_cleanup: DateTime.utc_now()
    }
    
    Logger.info("Cleanup completed. Deleted #{deleted_count} invitations. Total cleanups: #{new_state.cleanup_count}")
    
    # Schedule the next cleanup
    schedule_cleanup(state.cleanup_interval)
    
    {:noreply, new_state}
  end
  
  defp schedule_cleanup(interval) do
    Process.send_after(self(), :cleanup, interval)
  end
end
```

Then add it to your application's supervision tree:
```elixir
defmodule MyApp.Application do
  use Application
  
  def start(_type, _args) do
    children = [
      # ... other children
      {MyApp.InvitationCleanupCron, [
        cleanup_interval_ms: 2 * 60 * 60 * 1000,  # 2 hours
        days_old: 14  # Delete invitations expired more than 14 days ago
      ]}
    ]
    
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

**Manual cleanup:**
```elixir
iex> MyApp.InvitationCleanup.cleanup_old_expired_invitations(7)
Cleaned up 3 old expired invitations (older than 7 days)
3
```

## Phoenix Integration
You can use Usher with Phoenix. Here's how you might go about doing so:

### Controller Integration
Inside a controller:
```elixir
defmodule MyAppWeb.UserRegistrationController do
  use MyAppWeb, :controller
  
  def new(conn, params) do
    case validate_invitation_from_params(params) do
      {:ok, invitation} ->
        conn
        |> assign(:invitation, invitation)
        |> render(:new)
        
      {:error, reason} ->
        message = invitation_error_message(reason)
        conn
        |> put_flash(:error, message)
        |> redirect(to: ~p"/")
    end
  end
  
  def create(conn, %{"user" => user_params} = params) do
    case validate_invitation_from_params(params) do
      {:ok, invitation} ->
        # Create user and increment invitation count
        MyApp.Repo.transaction(fn ->
          with {:ok, user} <- create_user(user_params),
              {:ok, _} <- Usher.increment_joined_count(invitation) do
            conn
            |> put_flash(:info, "Account created successfully!")
            |> redirect(to: ~p"/dashboard")
          end
        end)
        
      {:error, reason} ->
        # This is a function that you can define,
        # e.g. in the fallback controller.
        handle_invitation_error(conn, reason)
    end
  end
  
  defp validate_invitation_from_params(params) do
    case params["invitation_token"] do
      token when is_binary(token) ->
        Usher.validate_invitation_token(token)
      
      _ ->
        {:error, :missing_token}
    end
  end
  
  defp invitation_error_message(:missing_token) do
    "An invitation is required to join. Please contact us for an invitation."
  end
  
  defp invitation_error_message(:invalid_token) do
    "This invitation link is invalid. Please check the link and try again."
  end
  
  defp invitation_error_message(:invitation_expired) do
    "This invitation has expired. Please request a new invitation."
  end
  
  defp invitation_error_message(_unknown) do
    "There was a problem with your invitation. Please try again or contact support."
  end
end
```

### LiveView Integration
Inside a LiveView:
```elixir
defmodule MyAppWeb.RegistrationLive do
  use MyAppWeb, :live_view

  def mount(params, _session, socket) do
    case validate_invitation_from_params(params) do
      {:ok, invitation} ->
        {:ok, assign(socket, :invitation, invitation)}
        
      {:error, reason} ->
        message = invitation_error_message(reason)
        {:ok, 
         socket
         |> put_flash(:error, message)
         |> redirect(to: ~p"/")}
    end
  end
  
  defp validate_invitation_from_params(params) do
    case params["invitation_token"] do
      token when is_binary(token) ->
        Usher.validate_invitation_token(token)
      
      _ ->
        {:error, :missing_token}
    end
  end
  
  defp invitation_error_message(:missing_token) do
    "An invitation is required to join. Please contact us for an invitation."
  end
  
  defp invitation_error_message(:invalid_token) do
    "This invitation link is invalid. Please check the link and try again."
  end
  
  defp invitation_error_message(:invitation_expired) do
    "This invitation has expired. Please request a new invitation."
  end
  
  defp invitation_error_message(_unknown) do
    "There was a problem with your invitation. Please try again or contact support."
  end
end
```

### Creating Your Own Phoenix Plug
If you want to create a custom plug for invitations, here's an example implementation you can use:
```elixir
defmodule MyApp.InvitationPlug do
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]
  import Plug.Conn

  @behaviour Plug

  def init(opts), do: opts

  def call(conn, opts) do
    redirect_on_error_to = Keyword.get(opts, :redirect_on_error_to, "/")
    flash_key = Keyword.fetch!(opts, :flash_key)

    case validate_invitation_from_params(conn.params) do
      {:ok, invitation} ->
        conn
        |> assign(:invitation, invitation)
        # If you don't need to invitation token for the entire session,
        # you can use `assign/3` instead.
        |> put_invitation_token_in_session(invitation.token)

      {:error, reason} ->
        message = invitation_error_message(reason)

        conn
        |> put_flash(flash_key, message)
        |> redirect(to: redirect_on_error_to)
        |> halt()
    end
  end

  def put_invitation_token_in_session(conn, token) do
    put_session(conn, :invitation_token, token)
  end

  def get_invitation_token_from_session(conn) do
    get_session(conn, :invitation_token)
  end

  def validate_invitation_from_session(conn) do
    case get_invitation_token_from_session(conn) do
      token when is_binary(token) ->
        Usher.validate_invitation_token(token)

      _ ->
        {:error, :missing_token}
    end
  end

  defp validate_invitation_from_params(params) do
    case params["invitation_token"] do
      token when is_binary(token) ->
        Usher.validate_invitation_token(token)

      _ ->
        {:error, :missing_token}
    end
  end

  defp invitation_error_message(:missing_token) do
    "An invitation is required to join. Please contact us for an invitation."
  end

  defp invitation_error_message(:invalid_token) do
    "This invitation link is invalid. Please check the link and try again."
  end

  defp invitation_error_message(:expired) do
    "This invitation has expired. Please request a new invitation."
  end

  defp invitation_error_message(_unknown) do
    "There was a problem with your invitation. Please try again or contact support."
  end
end
```

You can then use this plug in your router:
```elixir
pipeline :invitation_required do
  plug MyApp.InvitationPlug, redirect_on_error_to: "/contact"
end

scope "/signup" do
  pipe_through [:browser, :invitation_required]
  get "/", UserRegistrationController, :new
  post "/", UserRegistrationController, :create
end
```

## Configuration Options
| Option | Default | Description |
|--------|---------|-------------|
| `:repo` | **Required** | Your Ecto repository module |
| `:token_length` | `16` | Length of generated invitation tokens |
| `:default_expires_in` | `{7, :day}` | Default expiration period for new invitations |
| `:table_name` | `"usher_invitations"` | Database table name for invitations |
| `:validations` | `%{invitation: %{name_required: true}}` | Validation configuration for schemas |

## Examples

### Checking invitations and creating a new one
```elixir
# List all invitations
invitations = Usher.list_invitations()

# Create invitation with custom expiration
{:ok, invitation} = Usher.create_invitation(%{
  expires_at: DateTime.add(DateTime.utc_now(), 1, :month)
})

# Build shareable URL
invite_url = Usher.invitation_url(invitation.token, "https://myapp.com/signup")
```

## Development Setup

### Prerequisites
- Elixir 1.14+ and OTP 25+
- Docker and Docker Compose (for PostgreSQL)

### Getting Started
1. **Clone the repository**
   ```bash
   git clone https://github.com/typhoonworks/usher.git
   cd usher
   ```

2. **Install dependencies**
   ```bash
   mix deps.get
   ```

3. **Start PostgreSQL with Docker**
   ```bash
   docker-compose up -d
   ```
   This starts PostgreSQL on port 2345 and includes Adminer (database admin UI) on port 8085.

4. **Set up the test database**
   ```bash
   mix test.setup
   ```
   This creates the test database and runs migrations. You only need to run this once (or when you want to reset the test database).

5. **Run the tests**
   ```bash
   mix test
   ```

### Development Commands
- `mix test.setup` - Create and migrate test database (run once)
- `mix test` - Run all tests
- `mix lint` - Run formatter and dialyzer
- `mix docs` - Generate documentation
- `mix ecto.reset` - Reset test database (if needed)

### Database Access
When using Docker Compose, you can access:
- **PostgreSQL**: `localhost:2345` (user: `postgres`, password: `postgres`)
- **Adminer**: http://localhost:8085 (web-based database admin)

### Testing
Usher requires PostgreSQL to be running to execute its tests. The provided `docker-compose.yml` file makes this easy - just run `docker-compose up -d` before running tests.

**First time setup:**
```bash
docker-compose up -d
mix test.setup
mix test
```

**Subsequent test runs:**
```bash
mix test
```

For your own application tests, you can use the provided test fixtures:

```elixir
# In your test files
import Usher.TestFixtures

test "user registration with invitation" do
  invitation = invitation_fixture()
  # ... test your registration flow
end
```

## Contributing
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Follow the development setup above
4. Run tests (`mix test`)
5. Commit your changes (`git commit -am 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Inspiration
We first built this invitation system into [Accomplish](https://github.com/typhoonworks/accomplish) and then decided to open-source it.
