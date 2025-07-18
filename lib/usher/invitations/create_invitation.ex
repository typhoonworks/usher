defmodule Usher.Invitations.CreateInvitation do
  @moduledoc """
  Creates a new invitation with a token and default expiration datetime.
  """
  alias Usher.Config
  alias Usher.Invitation

  @alphanumeric_chars Enum.concat([?a..?z, ?A..?Z, ?0..?9])

  def call(attrs, opts \\ []) do
    attrs = Map.put_new_lazy(attrs, :token, &generate_invitation_token/0)
    attrs = Map.put_new_lazy(attrs, :expires_at, &default_expiration/0)

    %Invitation{}
    |> Invitation.changeset(attrs, opts)
    |> Config.repo().insert()
  end

  # Generates a secure invitation token.
  #
  # Uses cryptographically strong random bytes and encodes them as a URL-safe string.
  # The token length is configurable via `:token_length` config.
  defp generate_invitation_token do
    length = Config.token_length()

    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64(padding: false)
    |> String.slice(0, length)
    |> randomize_non_alphanumeric_chars()
  end

  # Returns the default expiration datetime for new invitations.
  #
  # Based on the `:default_expires_in` configuration.
  defp default_expiration do
    {amount, unit} = Config.default_expires_in()

    DateTime.add(DateTime.utc_now(), amount, unit)
  end

  defp randomize_non_alphanumeric_chars(email_local_part) do
    email_local_part
    |> String.replace(~r/[-_]/, fn _ -> <<Enum.random(@alphanumeric_chars)>> end)
  end
end
