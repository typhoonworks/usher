defmodule UsherTest do
  use Usher.DataCase, async: true

  describe "create_invitation/1" do
    test "creates invitation with default values" do
      assert {:ok, invitation} = Usher.create_invitation(%{name: "Test Invitation"})

      assert invitation.token
      assert invitation.name == "Test Invitation"
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
                 name: "Custom Invitation",
                 token: "custom_token",
                 expires_at: expires_at
               })

      assert invitation.token == "custom_token"
      assert invitation.expires_at == expires_at
    end

    test "fails with duplicate token" do
      token = "duplicate_token"

      assert {:ok, _} = Usher.create_invitation(%{name: "First", token: token})
      assert {:error, changeset} = Usher.create_invitation(%{name: "Second", token: token})
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

    test "returns {:error, :invitation_expired} for expired token" do
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
      assert get_in(entities, [Access.key!("456"), Access.find(&(&1["action"] == "registered"))])
      assert get_in(entities, [Access.key!("789"), Access.find(&(&1["action"] == "registered"))])
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
end
