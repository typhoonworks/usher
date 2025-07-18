defmodule Usher.TestFixtures do
  @moduledoc """
  Test fixtures for Usher tests.
  """

  alias Usher.{Test.Repo, Invitation, InvitationUsage}

  @doc """
  Generate a valid invitation.
  """
  def invitation_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        token: "test_token_" <> (System.unique_integer([:positive]) |> to_string()),
        name: "Test Invitation",
        expires_at: DateTime.add(DateTime.utc_now(), 7, :day),
        joined_count: 0
      })

    %Invitation{}
    |> Invitation.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Generate an expired invitation.
  """
  def expired_invitation_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        expires_at: DateTime.add(DateTime.utc_now(), 7, :day)
      })

    invitation = invitation_fixture(attrs)

    expires_at_in_the_past =
      DateTime.utc_now()
      |> DateTime.add(-1, :day)
      |> DateTime.truncate(:second)

    # There's no public changeset for setting an expired `expires_at` because
    # it's not a valid state for an invitation. So for tests, we directly update
    # the changeset.
    invitation
    |> Ecto.Changeset.change(expires_at: expires_at_in_the_past)
    |> Repo.update!()
  end

  @doc """
  Generate a used invitation (with joined_count > 0).
  """
  def used_invitation_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        joined_count: 1
      })

    invitation_fixture(attrs)
  end

  @doc """
  Generate an invitation without a name.
  """
  def invitation_without_name_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: nil
      })

    invitation_fixture(attrs)
  end

  @doc """
  Generate an invitation usage record.
  """
  def invitation_usage_fixture(invitation \\ nil, attrs \\ %{}) do
    invitation = invitation || invitation_fixture()

    attrs =
      Enum.into(attrs, %{
        invitation_id: invitation.id,
        entity_type: :user,
        entity_id: "test_entity_#{System.unique_integer([:positive])}",
        action: :registered,
        metadata: %{}
      })

    %InvitationUsage{}
    |> InvitationUsage.changeset(attrs)
    |> Repo.insert!()
  end
end
