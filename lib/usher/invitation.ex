defmodule Usher.Invitation do
  @moduledoc """
  Invitation schema for Usher.

  Represents an invitation with a unique token, expiration date, and usage tracking.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Usher.Config

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          token: String.t(),
          name: String.t() | nil,
          expires_at: DateTime.t(),
          usages: [Usher.InvitationUsage.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "usher_invitations" do
    field(:token, :string)
    field(:name, :string)
    field(:expires_at, :utc_datetime)

    has_many(:usages, Usher.InvitationUsage, foreign_key: :invitation_id)

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Changeset for creating and updating invitations.

  ## Options

    * `:require_name` - Whether to require the name field (defaults to Config.name_required?())

  ## Examples

      iex> Usher.Invitation.changeset(%Usher.Invitation{}, %{
      ...>   token: "abc123",
      ...>   expires_at: ~U[2024-12-31 23:59:59Z]
      ...> })
      %Ecto.Changeset{valid?: true}

      iex> Usher.Invitation.changeset(%Usher.Invitation{}, %{})
      %Ecto.Changeset{valid?: false, errors: [token: {"can't be blank", _}]}

      iex> Usher.Invitation.changeset(%Usher.Invitation{}, %{token: "abc", expires_at: ~U[2024-12-31 23:59:59Z]}, require_name: true)
      %Ecto.Changeset{valid?: false, errors: [name: {"can't be blank", _}]}
  """
  def changeset(invitation, attrs, opts \\ []) do
    invitation
    |> cast(attrs, [:token, :name, :expires_at])
    |> validate_required([:token, :expires_at])
    |> validate_name_if_required(opts)
    |> validate_future_date(:expires_at)
    |> unique_constraint(:token, name: :usher_invitations_token_index)
  end

  defp validate_name_if_required(changeset, opts) do
    require_name = Keyword.get(opts, :require_name, Config.name_required?())

    if require_name do
      validate_required(changeset, [:name])
    else
      changeset
    end
  end

  defp validate_future_date(changeset, field) do
    validate_change(changeset, field, fn field, value ->
      case DateTime.compare(value, DateTime.utc_now()) do
        :gt -> []
        _ -> [{field, "must be in the future"}]
      end
    end)
  end
end
