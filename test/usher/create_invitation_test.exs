defmodule Usher.Invitations.CreateInvitationTest do
  use Usher.DataCase, async: true
  use Mimic

  alias Usher.Config
  alias Usher.Invitation
  alias Usher.Invitations.CreateInvitation

  setup :verify_on_exit!

  setup do
    Mimic.copy(DateTime)
    Mimic.copy(Usher.Config)
    Mimic.copy(Usher.Test.Repo)

    :ok
  end

  describe "call/2" do
    test "auto-generated token is Base62 and correct length" do
      assert {:ok, invitation} = CreateInvitation.call(%{name: "Usher Generated Token"})

      token = invitation.token
      assert String.length(token) == Config.token_length()
      assert String.match?(token, ~r/^[0-9A-Za-z]+$/)
    end

    test "respects user-supplied token without altering it" do
      token = "custom_token_123"

      assert {:ok, invitation} =
               CreateInvitation.call(%{name: "User Supplied Token", token: token})

      assert invitation.token == token
    end

    test "generates unique tokens for multiple invitations" do
      {:ok, invitation1} = CreateInvitation.call(%{name: "First"})
      {:ok, invitation2} = CreateInvitation.call(%{name: "Second"})
      {:ok, invitation3} = CreateInvitation.call(%{name: "Third"})

      tokens = [invitation1.token, invitation2.token, invitation3.token]
      assert length(Enum.uniq(tokens)) == 3
    end
  end

  describe "default expiration" do
    test "sets default expiration based on config" do
      now = ~U[2024-01-01 12:00:00.000000Z]
      stub(DateTime, :utc_now, fn -> now end)

      expected_expiry = DateTime.add(now, 7, :day)

      assert {:ok, invitation} = CreateInvitation.call(%{name: "Test"})
      assert DateTime.compare(invitation.expires_at, expected_expiry) == :eq
    end

    test "respects user-supplied expiration date" do
      now = DateTime.utc_now()
      custom_expiry = DateTime.add(now, 30, :day)

      assert {:ok, invitation} =
               CreateInvitation.call(%{
                 name: "Custom Expiry",
                 expires_at: custom_expiry
               })

      assert DateTime.truncate(invitation.expires_at, :second) ==
               DateTime.truncate(custom_expiry, :second)
    end

    test "allows nil expiration for never-expiring invitations" do
      assert {:ok, invitation} =
               CreateInvitation.call(%{
                 name: "Never Expires",
                 expires_at: nil
               })

      assert invitation.expires_at == nil
    end
  end

  describe "token collision handling" do
    test "does not retry when user provides duplicate token" do
      user_token = "user_provided_token"
      {:ok, _first} = CreateInvitation.call(%{name: "First", token: user_token})

      assert {:error, changeset} = CreateInvitation.call(%{name: "Second", token: user_token})

      assert "has already been taken" in errors_on(changeset).token
    end

    test "collision handling exists for auto-generated tokens" do
      expect(Usher.Test.Repo, :insert, 5, fn _ ->
        changeset =
          %Invitation{}
          |> Ecto.Changeset.change()
          |> Ecto.Changeset.add_error(:token, "has already been taken")

        {:error, changeset}
      end)

      assert {:error, :too_many_token_generate_attempts} =
               CreateInvitation.call(%{name: "Too Many Attempts"})
    end
  end
end
