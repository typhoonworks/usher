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

        def change do
          Usher.Migration.create_usher_invitations_table()
        end
      end

  ### Configuration
  In your `config/config.exs` (or whichever environment you prefer),
  set up the Usher configuration:

      config :usher,
        repo: MyApp.Repo,
        token_length: 16,
        default_expires_in: {7, :days}
        table_name: "myapp_invitations"

  All the values above have defaults, which you can find in `Usher.Config`.

  ### Basic Usage

      # Create an invitation
      {:ok, invitation} = Usher.create_invitation()

      # Get invitation by token
      invitation = Usher.get_invitation_by_token("abc123")

      # Validate and consume invitation
      case Usher.validate_invitation_token("abc123") do
        {:ok, invitation} ->
          # Proceed with registration
          Usher.increment_joined_count(invitation)
        {:error, :invalid_token} ->
          # Handle invalid token
        {:error, :expired} ->
          # Handle expired token
      end

  ## Features

  - Token generation using cryptographic functions
  - Configurable token length and expiration periods
  - Framework-agnostic design works with any Ecto-based application
  """
  alias Usher.Config
  alias Usher.Invitation
  alias Usher.Invitations.CreateInvitation

  @doc """
  Creates a new invitation with a token and default expiration datetime.

  ## Options

    * `:expires_at` - Custom expiration datetime (overrides default)
    * `:token` - Custom token (overrides generated token)

  ## Examples

      iex> Usher.create_invitation()
      {:ok, %Usher.Invitation{token: "abc123...", expires_at: ~U[...]}}

      iex> Usher.create_invitation(expires_at: ~U[2024-12-31 23:59:59Z])
      {:ok, %Usher.Invitation{expires_at: ~U[2024-12-31 23:59:59Z]}}
  """
  def create_invitation(attrs \\ %{}) do
    CreateInvitation.call(attrs)
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
    case get_invitation_by_token(token) do
      {:ok, invitation} ->
        if DateTime.compare(invitation.expires_at, DateTime.utc_now()) == :gt do
          {:ok, invitation}
        else
          {:error, :invitation_expired}
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
