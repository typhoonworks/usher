defmodule Usher.InvitationTest do
  use Usher.DataCase, async: true

  alias Usher.Invitation

  describe "changeset/2" do
    test "valid changeset with required fields" do
      changeset =
        Invitation.changeset(%Invitation{}, %{
          name: "Test Invitation",
          token: "valid_token",
          expires_at: DateTime.add(DateTime.utc_now(), 1, :day)
        })

      assert changeset.valid?
    end

    test "invalid changeset without token" do
      changeset =
        Invitation.changeset(%Invitation{}, %{
          expires_at: DateTime.add(DateTime.utc_now(), 1, :day)
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).token
    end

    test "invalid changeset without expires_at" do
      changeset =
        Invitation.changeset(%Invitation{}, %{
          token: "valid_token"
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).expires_at
    end

    test "invalid changeset with past expiration date" do
      changeset =
        Invitation.changeset(%Invitation{}, %{
          token: "valid_token",
          expires_at: DateTime.add(DateTime.utc_now(), -1, :day)
        })

      refute changeset.valid?
      assert "must be in the future" in errors_on(changeset).expires_at
    end
  end
end
