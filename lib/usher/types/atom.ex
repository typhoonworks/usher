defmodule Usher.Types.Atom do
  @moduledoc """
  Custom Ecto type for handling atoms as strings for schemas.
  """
  use Ecto.Type

  def type, do: :string

  def cast(value), do: {:ok, value}

  def load(value), do: {:ok, String.to_atom(value)}

  def dump(value) when is_atom(value), do: {:ok, Atom.to_string(value)}
  def dump(value) when is_binary(value), do: {:ok, value}
end
