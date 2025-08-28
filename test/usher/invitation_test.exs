defmodule Usher.InvitationTest do
  use Usher.DataCase, async: true
  use Mimic

  alias Usher.Invitation

  setup :verify_on_exit!

  setup do
    Mimic.copy(Application)

    :ok
  end

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

    test "valid changeset without expires_at (never-expiring invitation)" do
      changeset =
        Invitation.changeset(%Invitation{}, %{
          token: "valid_token",
          name: "Never Expiring Invitation"
        })

      assert changeset.valid?
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

    test "name is required when name_required config is not set" do
      expect(Application, :get_env, fn :usher, :validations, _ ->
        %{}
      end)

      changeset =
        Invitation.changeset(%Invitation{}, %{
          token: "valid_token",
          expires_at: DateTime.add(DateTime.utc_now(), 1, :day)
        })

      refute changeset.valid?
    end

    test "name is not required when name_required config is false" do
      expect(Application, :get_env, fn :usher, :validations, _ ->
        %{invitation: %{name_required: false}}
      end)

      changeset =
        Invitation.changeset(%Invitation{}, %{
          token: "valid_token",
          expires_at: DateTime.add(DateTime.utc_now(), 1, :day)
        })

      assert changeset.valid?
    end

    @tag :custom_attributes_embedded_schema
    test "valid changeset with arbitrary custom_attributes" do
      custom_attributes = %{
        role: :manager,
        tags: ["marketing", "content"],
        department: "Marketing"
      }

      changeset =
        Invitation.changeset(%Invitation{}, %{
          name: "Test Invitation",
          token: "valid_token",
          expires_at: DateTime.add(DateTime.utc_now(), 1, :day),
          custom_attributes: custom_attributes
        })

      assert changeset.valid?

      assert is_map_key(changeset.changes, :custom_attributes)
      assert changeset.changes.custom_attributes.valid?
    end
  end
end
