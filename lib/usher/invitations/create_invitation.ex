defmodule Usher.Invitations.CreateInvitation do
  @moduledoc """
  Creates a new invitation with a token and default expiration datetime.
  """
  alias Usher.Config
  alias Usher.Invitation

  # Alphanumeric alphabet for base62 token generation (a-zA-Z0-9)
  @alphanumeric_chars Enum.concat([?a..?z, ?A..?Z, ?0..?9])
  @alphabet_size length(@alphanumeric_chars)
  @alphabet_tuple List.to_tuple(@alphanumeric_chars)
  # Largest multiple of @alphabet_size less than 256 to avoid modulo bias
  @unbiased_bound div(256, @alphabet_size) * @alphabet_size
  @max_random_token_generate_attempts 5

  def call(attrs, opts \\ []) do
    # Track if the token was provided by the caller to avoid auto-regeneration
    token_provided? = Map.has_key?(attrs, :token)

    attrs = Map.put_new_lazy(attrs, :token, &generate_invitation_token/0)
    attrs = Map.put_new_lazy(attrs, :expires_at, &default_expiration/0)

    if token_provided? do
      insert_user_token(attrs, opts)
    else
      insert_random_token_with_retry(attrs, opts, 0)
    end
  end

  # Generates a cryptographically secure, unbiased base62 (alphanumeric) token.
  defp generate_invitation_token do
    length = Config.token_length()

    base62_token(length)
  end

  defp default_expiration do
    {amount, unit} = Config.default_expires_in()

    DateTime.add(DateTime.utc_now(), amount, unit)
  end

  # Inserts the record and retries with a new token on unique token collision
  # only if the token was auto-generated (not user-specified).
  defp insert_random_token_with_retry(attrs, opts, attempt)
       when attempt < @max_random_token_generate_attempts do
    %Invitation{}
    |> Invitation.changeset(attrs, opts)
    |> Config.repo().insert()
    |> case do
      {:ok, invitation} ->
        {:ok, invitation}

      {:error, %Ecto.Changeset{}} = error ->
        maybe_handle_token_taken_error(error, attrs, opts, attempt)
    end
  end

  defp insert_random_token_with_retry(_attrs, _opts, _attempt) do
    {:error, :too_many_token_generate_attempts}
  end

  defp insert_user_token(attrs, opts) do
    %Invitation{}
    |> Invitation.changeset(attrs, opts)
    |> Config.repo().insert()
  end

  defp maybe_handle_token_taken_error({:error, changeset} = error, attrs, opts, attempt) do
    if token_taken_error?(changeset) do
      new_attrs = Map.put(attrs, :token, generate_invitation_token())
      insert_random_token_with_retry(new_attrs, opts, attempt + 1)
    else
      error
    end
  end

  defp token_taken_error?(%Ecto.Changeset{errors: errors}) do
    Enum.any?(errors, fn
      {:token, {"has already been taken", _}} -> true
      _ -> false
    end)
  end

  defp base62_token(len) when is_integer(len) and len > 0 do
    build_base62(len, [])
  end

  defp build_base62(0, acc), do: acc |> Enum.reverse() |> List.to_string()

  defp build_base62(needed, acc) do
    chunk = :crypto.strong_rand_bytes(max(needed * 2, 32))
    {acc, remaining} = take_from_bytes(chunk, needed, acc)

    # It's unlikely we'll run out of bytes when attempting to avoid modulo bias,
    # but if we do, we just generate another chunk of rand bytes and pick
    # bytes until we have enough characters in our token.
    build_base62(remaining, acc)
  end

  defp take_from_bytes(<<>>, needed, acc), do: {acc, needed}

  # If we've already collected enough characters, return immediately regardless of remaining bytes
  defp take_from_bytes(_rest, 0, acc), do: {acc, 0}

  defp take_from_bytes(<<byte, rest::binary>>, needed, acc) when byte < @unbiased_bound do
    idx = rem(byte, @alphabet_size)
    codepoint = elem(@alphabet_tuple, idx)

    take_from_bytes(rest, needed - 1, [codepoint | acc])
  end

  defp take_from_bytes(<<_byte, rest::binary>>, needed, acc) do
    take_from_bytes(rest, needed, acc)
  end
end
