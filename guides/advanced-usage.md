# Advanced Usage

This guide covers advanced patterns and techniques for using Usher in production applications.

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