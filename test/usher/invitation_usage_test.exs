defmodule Usher.InvitationUsageTest do
  use Usher.DataCase

  import Usher.TestFixtures

  alias Usher.InvitationUsage

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      invitation = invitation_fixture()

      attrs = %{
        invitation_id: invitation.id,
        entity_type: :user,
        entity_id: "123",
        action: :registered
      }

      changeset = InvitationUsage.changeset(%InvitationUsage{}, attrs)
      assert changeset.valid?
    end

    test "valid changeset with metadata" do
      invitation = invitation_fixture()

      attrs = %{
        invitation_id: invitation.id,
        entity_type: :user,
        entity_id: "123",
        action: :visited,
        metadata: %{ip: "192.168.1.1", user_agent: "Mozilla/5.0"}
      }

      changeset = InvitationUsage.changeset(%InvitationUsage{}, attrs)
      assert changeset.valid?
    end

    test "invalid changeset with missing required fields" do
      changeset = InvitationUsage.changeset(%InvitationUsage{}, %{})
      refute changeset.valid?

      assert "can't be blank" in errors_on(changeset).invitation_id
      assert "can't be blank" in errors_on(changeset).entity_type
      assert "can't be blank" in errors_on(changeset).entity_id
      assert "can't be blank" in errors_on(changeset).action
    end

    test "invalid changeset with unsupported entity_type" do
      invitation = invitation_fixture()

      attrs = %{
        invitation_id: invitation.id,
        entity_type: :unsupported_type,
        entity_id: "123",
        action: :registered
      }

      changeset = InvitationUsage.changeset(%InvitationUsage{}, attrs)
      refute changeset.valid?
      assert "must be one of: user, company, device" in errors_on(changeset).entity_type
    end

    test "invalid changeset with unsupported action" do
      invitation = invitation_fixture()

      attrs = %{
        invitation_id: invitation.id,
        entity_type: :user,
        entity_id: "123",
        action: :unsupported_action
      }

      changeset = InvitationUsage.changeset(%InvitationUsage{}, attrs)
      refute changeset.valid?
      assert "must be one of: visited, registered, activated" in errors_on(changeset).action
    end
  end
end
