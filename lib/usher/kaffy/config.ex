defmodule Usher.Kaffy.Config do
  @moduledoc """
  General configuration for Kaffy.
  """

  def create_resources(_conn) do
    [
      invitations: [
        resources: [
          invitations: [schema: Usher.Invitation, admin: Usher.Kaffy.InvitationAdmin],
          invitation_usages: [
            schema: Usher.InvitationUsage,
            admin: Usher.Kaffy.InvitationUsageAdmin
          ]
        ]
      ]
    ]
  end
end
