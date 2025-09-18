defmodule Usher.Invitation do
  @moduledoc """
  Invitation schema for Usher.

  Represents an invitation with a unique token, expiration date, and usage tracking.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.SoftDelete.Schema

  alias Usher.Config

  # Disabled because Dialyzer only sees the default value returned from
  # `Application.compile_env/3` called in `Usher.Config`, so it thinks
  # the value of `@custom_attributes_type` can only be `:map`.
  @dialyzer :no_match

  @custom_attributes_type Config.custom_attributes_type()

  @permitted_fields [:token, :name, :expires_at, :description, :max_uses, :uses, :deleted_at]

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          token: String.t(),
          max_uses: Integer.t(),
          uses: Integer.t(),
          name: String.t() | nil,
          description: String.t() | nil,
          expires_at: DateTime.t() | nil,
          deleted_at: DateTime.t() | nil,
          usages: [Usher.InvitationUsage.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "usher_invitations" do
    field(:token, :string)
    field(:name, :string)
    field(:description, :string)
    field(:expires_at, :utc_datetime)
    field(:max_uses, :integer, default: 1)
    field(:uses, :integer, default: 0)

    if @custom_attributes_type == :map do
      field(:custom_attributes, :map)
    else
      embeds_one(:custom_attributes, @custom_attributes_type)
    end

    has_many(:usages, Usher.InvitationUsage, foreign_key: :invitation_id)

    timestamps(type: :utc_datetime_usec)
    soft_delete_schema(auto_exclude_from_queries?: false)
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
    |> cast(attrs, permitted_fields())
    |> maybe_cast_embed()
    |> validate_required([:token])
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
    validate_change(changeset, field, fn
      field, %DateTime{} = datetime ->
        case DateTime.compare(datetime, DateTime.utc_now()) do
          :gt -> []
          _ -> [{field, "must be in the future"}]
        end

      _field, nil ->
        []
    end)
  end

  defp permitted_fields do
    if @custom_attributes_type == :map do
      # When a custom attribute embedded schema is provided,
      # we need to use `cast_embed/3` instead of adding :custom_attributes
      # to the list of permitted fields for `cast/3`
      [:custom_attributes | @permitted_fields]
    else
      @permitted_fields
    end
  end

  defp maybe_cast_embed(changeset) do
    if @custom_attributes_type == :map do
      changeset
    else
      cast_embed(changeset, :custom_attributes)
    end
  end

  import Ecto.Query

  @doc """
    Find the user invitation by an email stored in invitation_usage.

   ## Examples

      iex> Usher.find_invitation_by_email("test@example.com")
    %Ecto.Changeset{valid?: true}
  """

  def find_invitation_by_email(email) do
    results =
      from(i in Usher.InvitationUsage,
        where:
          fragment(
            "? @> ?",
            i.meta,
            fragment(
              "jsonb_build_object(?, ?)",
              "meta",
              fragment("jsonb_build_array(?)", type(^email, :string))
            )
          )
      )
      |> Config.repo().all()

    case results do
      nil ->
        nil

      [] ->
        nil

      results ->
          List.first(results)
          |> Config.repo().preload(:invitation)
    end
  end
end
