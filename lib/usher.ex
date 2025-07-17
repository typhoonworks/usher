defmodule Usher do
  @moduledoc """
  Usher is a web framework-agnostic invitation link management library for
  any Elixir application with Ecto.

  ## Getting Started

  To use Usher in your application, you need to:

  1. Run the migrations
  2. Configure Usher with your repo
  3. Use the functions provided to manage invitations

  ### Database Setup

  Generate and run the migration:

      mix ecto.gen.migration create_usher_tables

  Then add the Usher schema to your migration:

      defmodule MyApp.Repo.Migrations.CreateUsherTables do
        use Ecto.Migration
        import Usher.Migration

        def change do
          migrate_to_latest()
        end
      end

  For existing installations upgrading to a new version, generate a new migration:

      mix ecto.gen.migration upgrade_usher_tables

  And use the same `migrate_to_latest/0` function - it will automatically detect
  your current version and apply only the necessary migrations.

  ### Configuration
  In your `config/config.exs` (or whichever environment you prefer),
  set up the Usher configuration:

      config :usher,
        repo: MyApp.Repo,
        token_length: 16,
        default_expires_in: {7, :days},
        table_name: "myapp_invitations",
        name_required: false

  All the values above have defaults, which you can find in `Usher.Config`.

  ### Basic Usage

      # Create an invitation
      {:ok, invitation} = Usher.create_invitation()

      # Create an invitation with a name
      {:ok, invitation} = Usher.create_invitation(%{name: "Team Welcome"})

      # Get invitation by token
      invitation = Usher.get_invitation_by_token("abc123")

      # Validate and consume invitation
      case Usher.validate_invitation_token("abc123") do
        {:ok, invitation} ->
          # Proceed with registration
          Usher.increment_joined_count(invitation)
        {:error, :invalid_token} ->
          # Handle invalid token
        {:error, :invitation_expired} ->
          # Handle expired token
      end

      # Validate with name requirement
      case Usher.validate_invitation_token("abc123", require_name: true) do
        {:ok, invitation} ->
          # Proceed with registration (invitation has name)
          Usher.increment_joined_count(invitation)
        {:error, :name_required} ->
          # Handle missing name
          nil
        {:error, :invalid_token} ->
          # Handle invalid token
        {:error, :invitation_expired} ->
          # Handle expired token
      end

  ## Features

  - Token generation using cryptographic functions
  - Configurable token length and expiration periods
  - Optional name field with configurable validation
  - Versioned migration system for safe upgrades
  - Framework-agnostic design works with any Ecto-based application
  """
  alias Usher.Config
  alias Usher.Invitation
  alias Usher.Invitations.CreateInvitation

  @doc """
  Creates a new invitation with a token and default expiration datetime.

  ## Options

    * `:name` - Name for the invitation (required if configured)
    * `:expires_at` - Custom expiration datetime (overrides default)
    * `:token` - Custom token (overrides generated token)

  ## Examples

      iex> Usher.create_invitation()
      {:ok, %Usher.Invitation{token: "abc123...", expires_at: ~U[...]}}

      iex> Usher.create_invitation(name: "Welcome Team", expires_at: ~U[2024-12-31 23:59:59Z])
      {:ok, %Usher.Invitation{name: "Welcome Team", expires_at: ~U[2024-12-31 23:59:59Z]}}
  """
  def create_invitation(attrs \\ %{}) do
    CreateInvitation.call(attrs)
  end

  @doc """
  Creates a new invitation with a token and default expiration datetime.

  ## Attributes

    * `:name` - Name for the invitation
    * `:expires_at` - Custom expiration datetime (overrides default)
    * `:token` - Custom token (overrides generated token)

  ## Options

    * `:require_name` - Whether to require the name field (defaults to false)

  ## Examples

      iex> Usher.create_invitation(%{name: "Welcome Team"})
      {:ok, %Usher.Invitation{name: "Welcome Team"}}

      iex> Usher.create_invitation(%{}, require_name: true)
      {:error, %Ecto.Changeset{errors: [name: {"can't be blank", _}]}}
  """
  def create_invitation(attrs, opts) do
    CreateInvitation.call(attrs, opts)
  end

  @doc """
  Retrieves all invitations.

  ## Examples

      iex> Usher.list_invitations()
      [%Usher.Invitation{}, ...]
  """
  def list_invitations do
    Config.repo().all(Invitation)
  end

  @doc """
  Gets a single invitation by ID. Raises if not found.

  ## Examples

      iex> Usher.get_invitation!(id)
      %Usher.Invitation{}

      iex> Usher.get_invitation!("nonexistent")
      ** (Ecto.NoResultsError)
  """
  def get_invitation!(id) do
    Config.repo().get!(Invitation, id)
  end

  @doc """
  Gets an invitation by token.

  ## Examples

      iex> Usher.get_invitation_by_token("valid_token")
      %Usher.Invitation{}

      iex> Usher.get_invitation_by_token("invalid")
      nil
  """
  def get_invitation_by_token(token) when is_binary(token) do
    case Config.repo().get_by(Invitation, token: token) do
      %Invitation{} = invitation -> {:ok, invitation}
      nil -> {:error, :not_found}
    end
  end

  @doc """
  Validates an invitation token exists and returns the invitation if valid.

  Returns `{:ok, invitation}` if the token exists and hasn't expired.
  Returns `{:error, reason}` if the token is invalid or expired.

  ## Examples

      iex> Usher.validate_invitation_token("valid_token")
      {:ok, %Usher.Invitation{}}

      iex> Usher.validate_invitation_token("expired_token")
      {:error, :invitation_expired}

      iex> Usher.validate_invitation_token("invalid_token")
      {:error, :invalid_token}
  """
  def validate_invitation_token(token) do
    validate_invitation_token(token, [])
  end

  @doc """
  Validates an invitation token exists and returns the invitation if valid.

  Returns `{:ok, invitation}` if the token exists and hasn't expired.
  Returns `{:error, reason}` if the token is invalid, expired, or name validation fails.

  ## Options

    * `:require_name` - Whether to require the name field (defaults to false)

  ## Examples

      iex> Usher.validate_invitation_token("valid_token")
      {:ok, %Usher.Invitation{}}

      iex> Usher.validate_invitation_token("valid_token", require_name: true)
      {:error, :name_required}

      iex> Usher.validate_invitation_token("expired_token")
      {:error, :invitation_expired}

      iex> Usher.validate_invitation_token("invalid_token")
      {:error, :invalid_token}
  """
  def validate_invitation_token(token, opts) do
    case get_invitation_by_token(token) do
      {:ok, invitation} ->
        cond do
          DateTime.compare(invitation.expires_at, DateTime.utc_now()) != :gt ->
            {:error, :invitation_expired}

          Keyword.get(opts, :require_name, false) && is_nil(invitation.name) ->
            {:error, :name_required}

          true ->
            {:ok, invitation}
        end

      {:error, :not_found} ->
        {:error, :invalid_token}
    end
  end

  @doc """
  Increments the joined count for an invitation.

  This is typically called when a user successfully registers using the invitation.

  ## Examples

      iex> Usher.increment_joined_count(invitation)
      {:ok, %Usher.Invitation{joined_count: 1}}
  """
  def increment_joined_count(%Invitation{} = invitation) do
    invitation
    |> Invitation.increment_joined_count_changeset()
    |> Config.repo().update()
  end

  @doc """
  Deletes an invitation.

  ## Examples

      iex> Usher.delete_invitation(invitation)
      {:ok, %Usher.Invitation{}}

      iex> Usher.delete_invitation(bad_invitation)
      {:error, %Ecto.Changeset{}}
  """
  def delete_invitation(%Invitation{} = invitation) do
    Config.repo().delete(invitation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking invitation changes.

  ## Examples

      iex> Usher.change_invitation(invitation)
      %Ecto.Changeset{data: %Usher.Invitation{}}
  """
  def change_invitation(%Invitation{} = invitation, attrs \\ %{}) do
    Invitation.changeset(invitation, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking invitation changes with options.

  ## Options

    * `:require_name` - Whether to require the name field (defaults to false)

  ## Examples

      iex> Usher.change_invitation(invitation, %{name: "Test"})
      %Ecto.Changeset{data: %Usher.Invitation{}}

      iex> Usher.change_invitation(invitation, %{}, require_name: true)
      %Ecto.Changeset{data: %Usher.Invitation{}, errors: [name: {"can't be blank", _}]}
  """
  def change_invitation(%Invitation{} = invitation, attrs, opts) do
    Invitation.changeset(invitation, attrs, opts)
  end

  @doc """
  Builds an invitation URL for the given token and base URL.

  ## Examples

      iex> Usher.invitation_url("abc123", "https://example.com/signup")
      "https://example.com/signup?invitation_token=abc123"
  """
  def invitation_url(token, base_url) do
    uri = URI.parse(base_url)
    query = URI.encode_query([{"invitation_token", token}])

    %{uri | query: query} |> URI.to_string()
  end
end
