defmodule Usher.Token.Signature do
  @moduledoc """
  Helper functions to sign and verify user-supplied invitation tokens.

  Signing tokens is optional and does not change how tokens are stored. Use it when you
  want to distribute a signature along with a token, so that you can later check for
  authenticity, before looking up the invitation in the DB.
  """

  alias Usher.Config

  @type token :: String.t()
  @type signature :: String.t()

  @doc """
  Signs a token string using HMAC-SHA256 and returns a URL-encoded Base64 string.

  Requires `config :usher, signing_secret: "..."` to be set.
  """
  @spec sign(String.t()) :: String.t()
  def sign(token) when is_binary(token) do
    :crypto.mac(:hmac, :sha256, Config.signing_secret!(), token)
    |> Base.url_encode64(padding: false)
  end

  @doc """
  Verifies a signature against the given token. Signature must've been generated using
  the given token.
  """
  @spec verify(token(), signature()) ::
          {:ok, token()} | {:error, :invalid_signature}
  def verify(token, signature) do
    with :ok <- validate_signature(token, signature) do
      {:ok, token}
    end
  end

  defp validate_signature(token, encoded_signature) do
    expected_signature = :crypto.mac(:hmac, :sha256, Config.signing_secret!(), token)

    with {:ok, decoded_signature} <- decode_signature(encoded_signature) do
      if signature_binaries_equal?(expected_signature, decoded_signature) do
        :ok
      else
        {:error, :invalid_signature}
      end
    end
  end

  defp decode_signature(signature) do
    case Base.url_decode64(signature, padding: false) do
      {:ok, decoded_signature} -> {:ok, decoded_signature}
      :error -> {:error, :invalid_signature}
    end
  end

  defp signature_binaries_equal?(a, b) when byte_size(a) == byte_size(b) do
    :crypto.hash_equals(a, b)
  end

  defp signature_binaries_equal?(_, _), do: false
end
