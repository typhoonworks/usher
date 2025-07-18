defmodule Usher do
  @moduledoc """
  Usher is a web framework-agnostic invitation link management library for
  any Elixir application with Ecto.
  """
  alias Usher.Config
  alias Usher.Invitation
  alias Usher.InvitationUsage
  alias Usher.Invitations.CreateInvitation
  alias Usher.Invitations.InvitationUsageQuery

  @type entity_id :: String.t()
  @type invitation_usages_by_unique_entity :: list({entity_id(), map()})

  @doc """
  Creates a new invitation with a token and default expiration datetime.

  ## Attributes

    * `:name` - Name for the invitation
    * `:expires_at` - Custom expiration datetime (overrides default)
    * `:token` - Custom token (overrides generated token)

  ## Options

    * `:require_name` - Whether to require the name field (defaults to false)

  ## Examples

      iex> Usher.create_invitation()
      {:ok, %Usher.Invitation{token: "abc123...", expires_at: ~U[...]}}

      iex> Usher.create_invitation(%{name: "Welcome Team"})
      {:ok, %Usher.Invitation{name: "Welcome Team"}}

      iex> Usher.create_invitation(%{}, require_name: true)
      {:error, %Ecto.Changeset{errors: [name: {"can't be blank", _}]}}
  """
  def create_invitation(attrs \\ %{}, opts \\ []) do
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

  ## Options

    * `:require_name` - Whether to require the name field (defaults to false)

  ## Examples

      iex> Usher.change_invitation(invitation)
      %Ecto.Changeset{data: %Usher.Invitation{}}

      iex> Usher.change_invitation(invitation, %{name: "Test"})
      %Ecto.Changeset{data: %Usher.Invitation{}}

      iex> Usher.change_invitation(invitation, %{}, require_name: true)
      %Ecto.Changeset{data: %Usher.Invitation{}, errors: [name: {"can't be blank", _}]}
  """
  def change_invitation(%Invitation{} = invitation, attrs \\ %{}, opts \\ []) do
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

  # Entity Usage Tracking

  @doc """
  Records an entity's usage of an invitation.

  This provides flexible tracking of how invitations are used. You can track
  different actions (like :visited, :registered, :activated) and different
  entity types (like :user, :company, :device).

  ## Parameters

    * `invitation_or_token` - An `%Invitation{}` struct or invitation token string
    * `entity_type` - String describing the type of entity (e.g., :user, :company, :device)
    * `entity_id` - String ID of the entity
    * `action` - String describing the action (e.g., :visited, :registered, :activated)
    * `metadata` - Optional map of additional data (e.g., user agent, IP, custom fields)

  ## Examples

      # Track a user visiting signup page
      {:ok, usage} = Usher.track_invitation_usage(
        "abc123",
        :user,
        "user_123",
        :visited,
        %{ip: "192.168.1.1", user_agent: "Mozilla/5.0..."}
      )

      # Track a company registration
      {:ok, usage} = Usher.track_invitation_usage(
        invitation,
        :company,
        "company_456",
        :registered,
        %{plan: "premium", source: "email_campaign"}
      )

      # Tracking without metadata
      {:ok, usage} = Usher.track_invitation_usage("abc123", :user, "789", :activated)
  """
  @spec track_invitation_usage(
          Invitation.t() | String.t(),
          atom(),
          String.t(),
          atom(),
          map()
        ) ::
          {:ok, InvitationUsage.t()}
          | {:error, Ecto.Changeset.t()}
          | {:error, :invitation_not_found}
  def track_invitation_usage(invitation_or_token, entity_type, entity_id, action, metadata \\ %{})

  def track_invitation_usage(%Invitation{} = invitation, entity_type, entity_id, action, metadata) do
    attrs = %{
      invitation_id: invitation.id,
      entity_type: entity_type,
      entity_id: entity_id,
      action: action,
      metadata: metadata
    }

    %InvitationUsage{}
    |> InvitationUsage.changeset(attrs)
    |> Config.repo().insert()
  end

  def track_invitation_usage(token, entity_type, entity_id, action, metadata)
      when is_binary(token) do
    case get_invitation_by_token(token) do
      {:ok, invitation} ->
        track_invitation_usage(invitation, entity_type, entity_id, action, metadata)

      {:error, :not_found} ->
        {:error, :invitation_not_found}
    end
  end

  @doc """
  Gets all usage records for an invitation.

  ## Options

    * `:entity_type` - Filter by entity type
    * `:entity_id` - Filter by entity ID
    * `:action` - Filter by action
    * `:limit` - Limit number of results

  ## Examples

      # Get all usages for an invitation
      usages = Usher.list_invitation_usages(invitation)

      # Get only user registrations
      usages = Usher.list_invitation_usages(invitation, entity_type: :user, action: :registered)
  """
  @spec list_invitation_usages(Invitation.t(), keyword()) :: [InvitationUsage.t()]
  def list_invitation_usages(%Invitation{} = invitation, opts \\ []) do
    invitation
    |> InvitationUsageQuery.list_query(opts)
    |> Config.repo().all()
  end

  @doc """
  Gets all usage records for an invitiation, grouped by unique entity IDs.

  ## Options

    * `:entity_type` - Filter by entity type, useful for getting unique usages of a specific entity type
    * `:entity_id` - Filter by entity ID, useful for getting unique usages of a specific entity
    * `:action` - Filter by action, useful for getting unique usages of a specific action
    * `:limit` - Limit number of results

  ## Examples

      # All unique entities that used the invitation
      entities = Usher.get_invitation_unique_entities(invitation)
      # => [{"user", "123"}, {"company", "456"}]

      # Unique entities that registered
      entities = Usher.get_invitation_unique_entities(invitation, action: "registered")
  """
  @spec list_invitation_usages_by_unique_entity(Invitation.t(), keyword()) :: [
          {String.t(), [invitation_usages_by_unique_entity()]}
        ]
  def list_invitation_usages_by_unique_entity(%Invitation{} = invitation, opts \\ []) do
    invitation
    |> InvitationUsageQuery.unique_entities_query(opts)
    |> Config.repo().all()
  end

  @doc """
  Checks if a specific entity has performed an action on an invitation.

  ## Examples

      # Check if user 123 has registered
      if Usher.entity_used_invitation?(invitation, "user", "123", "registered") do
        # Entity has already registered
      end

      # Check if entity has any usage
      if Usher.entity_used_invitation?(invitation, "user", "123") do
        # Entity has used this invitation for any action
      end
  """
  def entity_used_invitation?(%Invitation{} = invitation, entity_type, entity_id, action \\ nil) do
    invitation
    |> InvitationUsageQuery.entity_exists_query(entity_type, entity_id, action)
    |> Config.repo().one()
  end
end
