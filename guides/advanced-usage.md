# Advanced Usage

This guide covers advanced patterns and techniques for using Usher in production applications.

## Signed Tokens

Usher supports cryptographically signed invitation tokens to prevent token guessing. This feature is particularly useful when you want to define user-friendly tokens that could be easily guessed, such as `youtube-2025`.

To use signed tokens, ensure you have set the `:signing_secret` configuration option. See the [Configuration Guide](configuration.md#basic-configuration) for details.

Generating and verifying signed tokens is straightforward:

```elixir
# Signed URL (optional, for user-supplied tokens)
{:ok, invitation, signature} =
  Usher.create_invitation_with_signed_token(%{token: "friendly-code-2025"})

signed_url =
  Usher.signed_invitation_url(invitation.token, signature, "https://myapp.com/signup")
# => "https://myapp.com/signup?invitation_token=friendly-code-2025&s=..."
```

> ⚠️ This feature only prevents guessing of user-supplied tokens by people who do not have access to the invitation token.

## Invitation Expiration Management

Usher provides flexible expiration management capabilities, allowing you to extend, modify, or remove expiration dates from invitations.

### Extending Existing Expiration Dates

Use `Usher.extend_invitation_expiration/2` to add time to an existing expiration date:

```elixir
# Extend an invitation by 7 days
{:ok, invitation} = Usher.extend_invitation_expiration(invitation, {7, :day})

# Extend by 2 hours
{:ok, invitation} = Usher.extend_invitation_expiration(invitation, {2, :hour})

# Works with expired invitations too
expired_invitation = Usher.get_invitation!("some-id")
{:ok, renewed_invitation} = Usher.extend_invitation_expiration(expired_invitation, {30, :day})
```

**Note:** This function only works with invitations that already have an expiration date. For never-expiring invitations, use `Usher.set_invitation_expiration/2`.

### Setting Specific Expiration Dates

Use `Usher.set_invitation_expiration/2` to set a specific expiration date:

```elixir
# Set a specific date
future_date = ~U[2025-12-31 23:59:59Z]
{:ok, invitation} = Usher.set_invitation_expiration(invitation, future_date)

# Set expiration to 30 days from now
future_date = DateTime.add(DateTime.utc_now(), 30, :day)
{:ok, invitation} = Usher.set_invitation_expiration(invitation, future_date)

# Works with any invitation, including never-expiring ones
future_date = DateTime.add(DateTime.utc_now(), 1, :week)
{:ok, invitation} = Usher.set_invitation_expiration(never_expiring_invitation, future_date)
```

### Creating Never-Expiring Invitations

Use `Usher.remove_invitation_expiration/1` to make invitations permanent:

```elixir
# Remove expiration from any invitation
{:ok, permanent_invitation} = Usher.remove_invitation_expiration(invitation)

# Now the invitation will never expire
{:ok, validated_invitation} = Usher.validate_invitation_token(permanent_invitation.token)
```

You can also create never-expiring invitations directly:

```elixir
{:ok, invitation} = Usher.create_invitation(%{
  name: "Permanent Team Invitation",
  expires_at: nil
})
```

### Expiration Management Strategies

#### 1. Dynamic Expiration Based on Usage

Extend invitations based on their usage patterns:

```elixir
defmodule MyApp.AdaptiveInvitations do
  def extend_if_active(invitation) do
    recent_usage_count =
      invitation
      |> Usher.list_invitation_usages(action: :visited)
      |> filter_recent_usages()
      |> Enum.count()

    if recent_usage_count > 5 do
      Usher.extend_invitation_expiration(invitation, {14, :day})
    else
      {:ok, invitation}
    end
  end

  def filter_recent_usages(invitation_usages) do
    cutoff_date = DateTime.utc_now() |> DateTime.add(-7, :day)

    Enum.filter(invitation_usages, fn invitation_usage ->
      case DateTime.compare(invitation_usage.inserted_at, cutoff_date) do
        :gt -> true
        _ -> false
      end
    end)
  end
end
```

#### 2. Conditional Expiration Removal

Make invitations permanent based on criteria:

```elixir
defmodule MyApp.PremiumInvitations do
  def upgrade_to_permanent(invitation, user) do
    if User.premium_account?(user) do
      Usher.remove_invitation_expiration(invitation)
    else
      {:ok, invitation}
    end
  end
end
```

## Invitation Cleanup Strategies

While Usher doesn't include built-in cleanup functionality, you can implement cleanup strategies to manage expired invitations.

### Basic Cleanup Module

Create a reusable cleanup module:

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

### Manual Cleanup

For one-off cleanup operations:

```elixir
# Remove all expired invitations
iex> MyApp.InvitationCleanup.cleanup_old_expired_invitations(0)
15

# Remove invitations expired more than 30 days ago
iex> MyApp.InvitationCleanup.cleanup_old_expired_invitations(30)
3
```

### Cleanup with Oban (Recommended)

For applications using Oban job processing:

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

Add to your Oban cron configuration:

```elixir
# config/config.exs
config :my_app, Oban,
  repo: MyApp.Repo,
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       # Clean up expired invitations daily at 2 AM
       {"0 2 * * *", MyApp.Workers.InvitationCleanupWorker}
     ]}
  ]
```

### Cleanup with GenServer

For applications wanting a self-contained cleanup process:

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

    Logger.info("Cleanup completed. Deleted #{deleted_count} invitations.")

    # Schedule the next cleanup
    schedule_cleanup(state.cleanup_interval)

    {:noreply, new_state}
  end

  defp schedule_cleanup(interval) do
    Process.send_after(self(), :cleanup, interval)
  end
end
```

Add to your application supervision tree:

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

## Custom Attributes for Invitations

Custom attributes allow defining attributes you can utilize after you validate an invitation. For example, you could utilize these attributes to determine the welcome message or the role a user should be assigned during account creation.

The examples here assume the default configuration for `:custom_attributes`, which is a field of type `Map`. If you'd like to use an embedded schema instead, see the [configuration guide](configuration.md#using-embedded-schema)

### Example: Setting User Role upon Registration

```elixir
defmodule MyApp.RoleBasedInvitations do
  def create_team_invitation(inviter, role, department) do
    Usher.create_invitation(%{
      name: "Join #{department} as #{role}",
      custom_attributes: %{
        invited_by: inviter.id,
        role: role,
        department: department,
        permissions: get_default_permissions(role),
        welcome_message: build_welcome_message(role, department)
      }
    })
  end

  def handle_registration(invitation_token, user_params) do
    with {:ok, invitation} <- Usher.validate_invitation_token(invitation_token),
         {:ok, user} <- create_user_from_invitation(invitation, user_params) do

      # Track the registration
      Usher.track_invitation_usage(invitation, :user, user.id, :registered)

      {:ok, user}
    end
  end

  defp create_user_from_invitation(invitation, user_params) do
    attrs = Map.take(
      invitation.custom_attributes,
      [:role, :department, :permissions, :invited_by]
    )

    MyApp.Accounts.create_user(attrs)
  end
end
```

### Example: Campaign Tracking Integration

Use custom attributes for marketing campaign tracking:

```elixir
defmodule MyApp.CampaignInvitations do
  def create_campaign_invitation(campaign_params) do
    Usher.create_invitation(%{
      name: campaign_params.subject,
      custom_attributes: %{
        campaign_id: campaign_params.campaign_id,
        campaign_name: campaign_params.campaign_name,
        utm_source: campaign_params.utm_source,
        utm_medium: campaign_params.utm_medium,
        utm_campaign: campaign_params.utm_campaign,
        landing_page: campaign_params.landing_page,
        expected_conversion_action: campaign_params.conversion_action,
        a_b_test_variant: campaign_params.ab_variant
      }
    })
  end

  def track_campaign_interaction(invitation_token, entity_id, action) do
    with {:ok, invitation} <- Usher.validate_invitation_token(invitation_token) do

      # Track the action with Usher
      Usher.track_invitation_usage(invitation, :user, entity_id, action)

      # Also send to your analytics service
      send_to_analytics(invitation, entity_id, action)

      {:ok, invitation}
    end
  end

  defp send_to_analytics(invitation, entity_id, action) do
    attrs = invitation.custom_attributes

    analytics_event = %{
      user_id: entity_id,
      event: "invitation_#{action}",
      properties: %{
        campaign_id: attrs.campaign_id,
        campaign_name: attrs.campaign_name,
        utm_source: attrs.utm_source,
        utm_medium: attrs.utm_medium,
        utm_campaign: attrs.utm_campaign,
        ab_variant: attrs.a_b_test_variant,
      }
    }

    MyApp.Analytics.track_event(analytics_event)
  end
end
```

## Complex Validation Patterns

### Multi-Step Validation

```elixir
defmodule MyApp.InvitationValidator do
  def validate_with_context(token, context \\ %{}) do
    with {:ok, invitation} <- Usher.validate_invitation_token(token),
         :ok <- check_usage_limits(invitation, context) do
      {:ok, invitation}
    end
  end

  defp check_usage_limits(invitation, context) do
    max_uses = Map.get(context, :max_uses, 100)

    invitation_usage_count =
      invitation
      |> Usher.list_invitation_usages_by_unique_entity(action: :joined)
      |> Enum.count()

    if invitation_usage_count >= max_uses do
      {:error, :usage_limit_exceeded}
    else
      :ok
    end
  end
end

# Usage
case MyApp.InvitationValidator.validate_with_context("abc123", %{
  max_uses: 50
}) do
  {:ok, invitation} -> proceed_with_registration(invitation)
  {:error, reason} -> handle_validation_error(reason)
end
```
