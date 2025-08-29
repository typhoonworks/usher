defmodule Usher.CustomAttributesEmbeddedSchema do
  @moduledoc """
  An example embedded schema to demonstrate how users might
  opt to use a custom type for the `:custom_attributes`
  field of the `Usher.Invitation` schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field(:role, Ecto.Enum, values: [:admin, :manager, :user])
    field(:tags, {:array, :string})
    field(:department, :string)
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:role, :tags, :department])
  end
end
