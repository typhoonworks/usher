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
          joined_count: integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema Config.table_name() do
    field(:token, :string)
    field(:name, :string)
    field(:expires_at, :utc_datetime)
    field(:joined_count, :integer, default: 0)

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
    |> cast(attrs, [:token, :name, :expires_at, :joined_count])
    |> validate_required([:token, :expires_at])
    |> validate_name_if_required(opts)
    |> validate_number(:joined_count, greater_than_or_equal_to: 0)
    |> validate_future_date(:expires_at)
    |> unique_constraint(:token, name: :usher_invitations_token_index)
  end

  @doc """
  Changeset for incrementing the joined count.

  This is for when a user successfully registers using the invitation.

  ## Examples

      iex> invitation = %Usher.Invitation{joined_count: 0}
      iex> Usher.Invitation.increment_joined_count_changeset(invitation)
      %Ecto.Changeset{changes: %{joined_count: 1}}
  """
  def increment_joined_count_changeset(invitation) do
    change(invitation, joined_count: invitation.joined_count + 1)
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
