defmodule Usher.Token.SignatureTest do
  use ExUnit.Case, async: true

  alias Usher.Token.Signature

  test "sign/1 and verify/1 succeed when tokens are the same" do
    token = "user_defined_token_123"
    signature = Signature.sign(token)

    assert {:ok, ^token} = Signature.verify(token, signature)
  end

  test "fails when token does not match signature generated from another token" do
    token = "abc"
    signature = Signature.sign(token)

    assert {:error, :invalid_signature} = Signature.verify("not-the-original-token", signature)
  end
end
