defmodule UsherTest do
  use Usher.DataCase, async: true

  describe "create_invitation/1" do
    test "creates invitation with default values" do
      assert {:ok, invitation} = Usher.create_invitation(%{name: "Test Invitation"})

      assert invitation.token
      assert invitation.name == "Test Invitation"
      assert invitation.expires_at
      # Configured in `config.exs`
      assert String.length(invitation.token) == 16
    end

    test "creates invitation with user-defined attributes" do
      expires_at =
        DateTime.utc_now()
        |> DateTime.add(30, :day)
        |> DateTime.truncate(:second)

      assert {:ok, invitation} =
               Usher.create_invitation(%{
                 name: "Custom Invitation",
                 token: "custom_token",
                 expires_at: expires_at
               })

      assert invitation.token == "custom_token"
      assert invitation.expires_at == expires_at
    end

    test "creates invitation with custom_attributes as :map" do
      custom_attributes = %{
        role: :manager,
        tags: ["marketing", "content"],
        department: "Marketing"
      }

      assert {:ok, invitation} =
               Usher.create_invitation(%{
                 name: "Custom Invitation",
                 token: "custom_token",
                 custom_attributes: custom_attributes
               })

      assert invitation.custom_attributes == custom_attributes
    end

    @tag :custom_attributes_embedded_schema
    test "creates invitation with custom_attributes as embedded schema" do
      custom_attributes = %{
        role: :manager,
        tags: ["marketing", "content"],
        department: "Marketing"
      }

      assert {:ok, invitation} =
               Usher.create_invitation(%{
                 name: "Custom Invitation",
                 token: "custom_token",
                 custom_attributes: custom_attributes
               })

      assert %Usher.CustomAttributesEmbeddedSchema{} =
               actual_custom_attributes = invitation.custom_attributes

      assert Map.from_struct(actual_custom_attributes) == custom_attributes
    end

    test "fails with duplicate token" do
      token = "duplicate_token"

      assert {:ok, _} = Usher.create_invitation(%{name: "First", token: token})
      assert {:error, changeset} = Usher.create_invitation(%{name: "Second", token: token})
      assert "has already been taken" in errors_on(changeset).token
    end
  end

  describe "create_invitation_with_signed_token/1" do
    test "returns token signature along with created invitation" do
      assert {:ok, invitation, signature} =
               Usher.create_invitation_with_signed_token(%{
                 name: "Super Secret Invitation",
                 token: "super-secret-invitation"
               })

      assert invitation.token == "super-secret-invitation"
      assert invitation.name == "Super Secret Invitation"
      assert invitation.expires_at

      assert String.length(signature) > 0
    end

    test "returns {:ok, token_required} if no token is provided" do
      assert {:error, :token_required} =
               Usher.create_invitation_with_signed_token(%{name: "No Token"})
    end
  end

  describe "validate_invitation_token/1" do
    test "returns {:ok, invitation} for valid token" do
      invitation = invitation_fixture()

      assert {:ok, ^invitation} = Usher.validate_invitation_token(invitation.token)
    end

    test "returns {:error, :invalid_token} for nonexistent token" do
      assert {:error, :not_found} = Usher.validate_invitation_token("nonexistent")
    end

    test "returns {:error, :invitation_expired} for expired token" do
      invitation = expired_invitation_fixture()

      assert {:error, :invitation_expired} = Usher.validate_invitation_token(invitation.token)
    end
  end

  describe "validate_secure_invitation_token/1" do
    test "verifies token against signature" do
      {:ok, invitation, signature} =
        Usher.create_invitation_with_signed_token(%{
          name: "Super Secret Invitation",
          token: "super-secret-invitation"
        })

      assert {:ok, ^invitation} =
               Usher.validate_secure_invitation_token(invitation.token, signature)
    end

    test "returns {:error, :invalid_signature} when signature wasn't generated from the token" do
      assert {:error, :invalid_signature} =
               Usher.validate_secure_invitation_token("token", "invalid-signature")
    end
  end

  describe "invitation_url/2" do
    test "builds URL with invitation token" do
      url = Usher.invitation_url("abc123", "https://example.com/signup")
      assert url == "https://example.com/signup?invitation_token=abc123"
    end
  end

  describe "signed_invitation_url/2" do
    test "builds URL with invitation token" do
      url =
        Usher.signed_invitation_url(
          "abc123",
          "Z7aPPn0OT3ARmifwmGJkMRec74H1AV-RwtpUqN8Ev2c",
          "https://example.com/signup"
        )

      assert url ==
               "https://example.com/signup?invitation_token=abc123&s=Z7aPPn0OT3ARmifwmGJkMRec74H1AV-RwtpUqN8Ev2c"
    end
  end

  describe "track_invitation_usage/5" do
    test "tracks usage with invitation struct" do
      invitation = invitation_fixture()

      assert {:ok, usage} =
               Usher.track_invitation_usage(
                 invitation,
                 :user,
                 "123",
                 :registered,
                 %{plan: "premium"}
               )

      assert usage.invitation_id == invitation.id
      assert usage.entity_type == :user
      assert usage.entity_id == "123"
      assert usage.action == :registered
      assert usage.metadata == %{plan: "premium"}
    end

    test "tracks usage with invitation token" do
      invitation = invitation_fixture()

      assert {:ok, usage} =
               Usher.track_invitation_usage(
                 invitation.token,
                 :company,
                 "456",
                 :visited
               )

      assert usage.invitation_id == invitation.id
      assert usage.entity_type == :company
      assert usage.entity_id == "456"
      assert usage.action == :visited
      assert usage.metadata == %{}
    end

    test "fails with invalid invitation token" do
      assert {:error, :invitation_not_found} =
               Usher.track_invitation_usage(
                 "invalid_token",
                 :user,
                 "123",
                 :registered
               )
    end

    test "allows same entity to perform different actions" do
      invitation = invitation_fixture()

      assert {:ok, _} = Usher.track_invitation_usage(invitation, :user, "123", :visited)
      assert {:ok, _} = Usher.track_invitation_usage(invitation, :user, "123", :registered)
    end
  end

  describe "list_invitation_usages/2" do
    test "lists all usages for an invitation" do
      invitation = invitation_fixture()

      {:ok, usage1} = Usher.track_invitation_usage(invitation, :user, "123", :visited)
      {:ok, usage2} = Usher.track_invitation_usage(invitation, :user, "456", :registered)

      usages = Usher.list_invitation_usages(invitation)

      assert length(usages) == 2
      # More recent first
      assert usage2 in usages
      assert usage1 in usages
    end

    test "filters by entity_type" do
      invitation = invitation_fixture()

      {:ok, _} = Usher.track_invitation_usage(invitation, :user, "123", :visited)
      {:ok, usage2} = Usher.track_invitation_usage(invitation, :company, "456", :registered)

      usages = Usher.list_invitation_usages(invitation, entity_type: "company")

      assert length(usages) == 1
      assert usage2 in usages
    end

    test "filters by entity_id" do
      invitation = invitation_fixture()

      {:ok, usage1} = Usher.track_invitation_usage(invitation, :user, "123", :visited)
      {:ok, _} = Usher.track_invitation_usage(invitation, :user, "456", :registered)

      usages = Usher.list_invitation_usages(invitation, entity_id: "123")

      assert length(usages) == 1
      assert usage1 in usages
    end

    test "filters by action" do
      invitation = invitation_fixture()

      {:ok, usage1} = Usher.track_invitation_usage(invitation, :user, "123", :visited)
      {:ok, _} = Usher.track_invitation_usage(invitation, :user, "456", :registered)

      usages = Usher.list_invitation_usages(invitation, action: "visited")

      assert length(usages) == 1
      assert usage1 in usages
    end

    test "limits results" do
      invitation = invitation_fixture()

      {:ok, _} = Usher.track_invitation_usage(invitation, :user, "1", :visited)
      {:ok, _} = Usher.track_invitation_usage(invitation, :user, "2", :visited)
      {:ok, _} = Usher.track_invitation_usage(invitation, :user, "3", :visited)

      usages = Usher.list_invitation_usages(invitation, limit: 2)

      assert length(usages) == 2
    end
  end

  describe "list_invitation_usages_by_unique_entity/2" do
    test "returns unique entities" do
      invitation = invitation_fixture()

      {:ok, _} = Usher.track_invitation_usage(invitation, :user, "123", :visited)
      {:ok, _} = Usher.track_invitation_usage(invitation, :user, "123", :registered)
      {:ok, _} = Usher.track_invitation_usage(invitation, :company, "456", :registered)

      entities =
        invitation
        |> Usher.list_invitation_usages_by_unique_entity()
        |> Enum.into(%{})

      keys = Map.keys(entities)
      assert length(keys) == 2
      assert "123" in keys
      assert "456" in keys
    end

    test "filters by entity_type" do
      invitation = invitation_fixture()

      {:ok, _} = Usher.track_invitation_usage(invitation, :user, "123", :visited)
      {:ok, _} = Usher.track_invitation_usage(invitation, :user, "456", :registered)
      {:ok, _} = Usher.track_invitation_usage(invitation, :company, "789", :registered)

      entities =
        invitation
        |> Usher.list_invitation_usages_by_unique_entity(entity_type: :company)
        |> Enum.into(%{})

      keys = Map.keys(entities)
      assert length(keys) == 1
      assert "789" in keys
    end

    test "filters by entity_id" do
      invitation = invitation_fixture()

      {:ok, _} = Usher.track_invitation_usage(invitation, :user, "123", :visited)
      {:ok, _} = Usher.track_invitation_usage(invitation, :user, "456", :registered)

      entities =
        invitation
        |> Usher.list_invitation_usages_by_unique_entity(entity_id: "123")
        |> Enum.into(%{})

      keys = Map.keys(entities)
      assert length(keys) == 1
      assert "123" in keys
    end

    test "filters by action" do
      invitation = invitation_fixture()

      {:ok, _} = Usher.track_invitation_usage(invitation, :user, "123", :visited)
      {:ok, _} = Usher.track_invitation_usage(invitation, :user, "456", :registered)
      {:ok, _} = Usher.track_invitation_usage(invitation, :company, "789", :registered)

      entities =
        invitation
        |> Usher.list_invitation_usages_by_unique_entity(action: "registered")
        |> Enum.into(%{})

      keys = Map.keys(entities)
      assert length(keys) == 2

      assert get_in(entities, [Access.key!("456"), Access.filter(&(&1["action"] == "registered"))])

      assert get_in(entities, [Access.key!("789"), Access.filter(&(&1["action"] == "registered"))])
    end
  end

  describe "entity_used_invitation?/4" do
    test "returns true when entity used invitation" do
      invitation = invitation_fixture()

      {:ok, _} = Usher.track_invitation_usage(invitation, :user, "123", :registered)

      assert Usher.entity_used_invitation?(invitation, "user", "123")
      assert Usher.entity_used_invitation?(invitation, "user", "123", "registered")
    end

    test "returns false when entity did not use invitation" do
      invitation = invitation_fixture()

      refute Usher.entity_used_invitation?(invitation, "user", "123")
      refute Usher.entity_used_invitation?(invitation, "user", "123", "registered")
    end

    test "returns false when entity used invitation for different action" do
      invitation = invitation_fixture()

      {:ok, _} = Usher.track_invitation_usage(invitation, :user, "123", :visited)

      assert Usher.entity_used_invitation?(invitation, "user", "123")
      assert Usher.entity_used_invitation?(invitation, "user", "123", "visited")
      refute Usher.entity_used_invitation?(invitation, "user", "123", "registered")
    end
  end

  describe "extend_invitation_expiration/2" do
    test "extends invitation with existing expiration" do
      invitation = invitation_fixture()
      original_expires_at = invitation.expires_at

      assert {:ok, updated_invitation} = Usher.extend_invitation_expiration(invitation, {7, :day})

      expected_expires_at = DateTime.add(original_expires_at, 7, :day)
      assert DateTime.compare(updated_invitation.expires_at, expected_expires_at) == :eq
      # Verify it's now in the future
      assert DateTime.compare(updated_invitation.expires_at, DateTime.utc_now()) == :gt
    end

    test "extends expired invitation" do
      invitation = expired_invitation_fixture()
      original_expires_at = invitation.expires_at

      assert {:ok, updated_invitation} =
               Usher.extend_invitation_expiration(invitation, {25, :hour})

      expected_expires_at = DateTime.add(original_expires_at, 25, :hour)
      assert DateTime.compare(updated_invitation.expires_at, expected_expires_at) == :eq
      # Verify it's now in the future
      assert DateTime.compare(updated_invitation.expires_at, DateTime.utc_now()) == :gt
    end

    test "fails to extend never-expiring invitation" do
      invitation = never_expiring_invitation_fixture()

      assert {:error, :no_expiration_to_extend} =
               Usher.extend_invitation_expiration(invitation, {1, :week})
    end

    test "validates positive duration amounts" do
      invitation = invitation_fixture()

      assert_raise FunctionClauseError, fn ->
        Usher.extend_invitation_expiration(invitation, {0, :day})
      end

      assert_raise FunctionClauseError, fn ->
        Usher.extend_invitation_expiration(invitation, {-1, :day})
      end
    end
  end

  describe "set_invitation_expiration/2" do
    test "sets specific expiration date" do
      invitation = invitation_fixture()
      target_date = ~U[2030-12-31 23:59:59Z]

      assert {:ok, updated_invitation} = Usher.set_invitation_expiration(invitation, target_date)

      assert updated_invitation.expires_at == target_date
    end

    test "sets expiration on never-expiring invitation" do
      invitation = never_expiring_invitation_fixture()
      target_date = DateTime.add(DateTime.utc_now(), 30, :day) |> DateTime.truncate(:second)

      assert {:ok, updated_invitation} = Usher.set_invitation_expiration(invitation, target_date)

      assert updated_invitation.expires_at == target_date
    end

    test "sets expiration on expired invitation" do
      invitation = expired_invitation_fixture()
      target_date = DateTime.add(DateTime.utc_now(), 1, :hour) |> DateTime.truncate(:second)

      assert {:ok, updated_invitation} = Usher.set_invitation_expiration(invitation, target_date)

      assert updated_invitation.expires_at == target_date
    end

    test "fails with invalid changeset for past date" do
      invitation = invitation_fixture()
      past_date = DateTime.add(DateTime.utc_now(), -1, :day)

      assert {:error, changeset} = Usher.set_invitation_expiration(invitation, past_date)
      assert "must be in the future" in errors_on(changeset).expires_at
    end
  end

  describe "remove_invitation_expiration/1" do
    test "removes expiration from invitation" do
      invitation = invitation_fixture()

      assert {:ok, updated_invitation} = Usher.remove_invitation_expiration(invitation)

      assert updated_invitation.expires_at == nil
    end

    test "removes expiration from expired invitation" do
      invitation = expired_invitation_fixture()

      assert {:ok, updated_invitation} = Usher.remove_invitation_expiration(invitation)

      assert updated_invitation.expires_at == nil
    end

    test "works on already never-expiring invitation" do
      invitation = never_expiring_invitation_fixture()

      assert {:ok, updated_invitation} = Usher.remove_invitation_expiration(invitation)

      assert updated_invitation.expires_at == nil
    end
  end

  describe "validate_invitation_token/1 with never-expiring invitations" do
    test "validates never-expiring invitation token" do
      invitation = never_expiring_invitation_fixture()

      assert {:ok, ^invitation} = Usher.validate_invitation_token(invitation.token)
    end

    test "validates expired invitation after removing expiration" do
      invitation = expired_invitation_fixture()

      # Should be expired initially
      assert {:error, :invitation_expired} = Usher.validate_invitation_token(invitation.token)

      # Remove expiration
      {:ok, updated_invitation} = Usher.remove_invitation_expiration(invitation)

      # Should now be valid
      assert {:ok, ^updated_invitation} = Usher.validate_invitation_token(invitation.token)
    end
  end
end
