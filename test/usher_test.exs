defmodule UsherTest do
  use Usher.DataCase, async: true

  describe "create_invitation/1" do
    test "creates invitation with default values" do
      assert {:ok, invitation} = Usher.create_invitation()

      assert invitation.token
      assert invitation.expires_at
      assert invitation.joined_count == 0
      # Configured in `config.exs`
      assert String.length(invitation.token) == 16
    end

    test "creates invitation with custom attributes" do
      expires_at =
        DateTime.utc_now()
        |> DateTime.add(30, :day)
        |> DateTime.truncate(:second)

      assert {:ok, invitation} =
               Usher.create_invitation(%{
                 token: "custom_token",
                 expires_at: expires_at
               })

      assert invitation.token == "custom_token"
      assert invitation.expires_at == expires_at
    end

    test "fails with duplicate token" do
      token = "duplicate_token"

      assert {:ok, _} = Usher.create_invitation(%{token: token})
      assert {:error, changeset} = Usher.create_invitation(%{token: token})
      assert "has already been taken" in errors_on(changeset).token
    end
  end

  describe "validate_invitation_token/1" do
    test "returns {:ok, invitation} for valid token" do
      invitation = invitation_fixture()

      assert {:ok, ^invitation} = Usher.validate_invitation_token(invitation.token)
    end

    test "returns {:error, :invalid_token} for nonexistent token" do
      assert {:error, :invalid_token} = Usher.validate_invitation_token("nonexistent")
    end

    test "returns {:error, :expired} for expired token" do
      invitation = expired_invitation_fixture()

      assert {:error, :invitation_expired} = Usher.validate_invitation_token(invitation.token)
    end
  end

  describe "increment_joined_count/1" do
    test "increments the joined count" do
      invitation = invitation_fixture(%{joined_count: 0})
      assert {:ok, updated} = Usher.increment_joined_count(invitation)
      assert updated.joined_count == 1
    end
  end

  describe "invitation_url/2" do
    test "builds URL with invitation token" do
      url = Usher.invitation_url("abc123", "https://example.com/signup")
      assert url == "https://example.com/signup?invitation_token=abc123"
    end
  end
end
