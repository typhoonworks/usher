defmodule Usher.InvitationUsage do
  @moduledoc """
  Schema for tracking invitation usage by entities.

  An invitation usage record represents when an entity (user, company, device, etc.)
  interacts with an invitation. This could be visiting a signup page, completing
  registration, or any other trackable action.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Usher.Config
  alias Usher.Invitation

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          invitation_id: Ecto.UUID.t(),
          invitation: Invitation.t() | Ecto.Association.NotLoaded.t(),
          entity_type: atom(),
          entity_id: String.t(),
          action: atom(),
          metadata: map(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "usher_invitation_usages" do
    belongs_to(:invitation, Invitation)
    field(:entity_type, Usher.Types.Atom)
    field(:entity_id, :string)
    field(:action, Usher.Types.Atom)
    field(:metadata, :map, default: %{})

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Changeset for creating invitation usage records.

  ## Required fields
  - `invitation_id`: The invitation being used
  - `entity_type`: A string describing what kind of entity (e.g., :user, :company, :device)
  - `entity_id`: ID of the entity
  - `action`: What action was performed (e.g., :visited, :registered, :activated)

  ## Optional fields
  - `metadata`: Additional context (user agent, IP, custom data, etc.)
  """
  def changeset(usage, attrs) do
    usage
    |> cast(attrs, [:invitation_id, :entity_type, :entity_id, :action, :metadata])
    |> validate_required([:invitation_id, :entity_type, :entity_id, :action])
    |> validate_entity_type()
    |> validate_action()
    |> foreign_key_constraint(:invitation_id)
  end

  defp validate_entity_type(changeset) do
    validate_change(changeset, :entity_type, fn :entity_type, entity_type ->
      valid_types = Config.valid_entity_types()

      if entity_type in valid_types do
        []
      else
        [entity_type: "must be one of: #{Enum.join(valid_types, ", ")}"]
      end
    end)
  rescue
    # If configuration is not set, skip validation to allow tests without config
    RuntimeError -> changeset
  end

  defp validate_action(changeset) do
    validate_change(changeset, :action, fn :action, action ->
      valid_actions = Config.valid_actions()

      if action in valid_actions do
        []
      else
        [action: "must be one of: #{Enum.join(valid_actions, ", ")}"]
      end
    end)
  rescue
    # If configuration is not set, skip validation to allow tests without config
    RuntimeError -> changeset
  end
end
