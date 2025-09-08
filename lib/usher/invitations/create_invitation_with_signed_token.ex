defmodule Usher.Invitations.CreateInvitationWithSignedToken do
  @moduledoc """
  Creates an invitation and returns a signed presentation token alongside it.

  Only works when a `:token` is supplied in the attrs.
  """

  alias Usher.Invitation
  alias Usher.Invitations.CreateInvitation
  alias Usher.Token.Signature

  def call(attrs, opts \\ []) do
    with {:ok, token} <- fetch_token(attrs) do
      create_invitation(attrs, token, opts)
    end
  end

  defp create_invitation(attrs, token, opts) do
    case CreateInvitation.call(attrs, opts) do
      {:ok, %Invitation{} = invitation} -> {:ok, invitation, Signature.sign(token)}
      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
    end
  end

  defp fetch_token(%{token: token}) do
    case token do
      token when is_binary(token) and byte_size(token) > 0 ->
        {:ok, token}

      _ ->
        {:error, :token_required}
    end
  end

  defp fetch_token(_), do: {:error, :token_required}
end
