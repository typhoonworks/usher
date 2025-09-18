defmodule Usher.Tasks do
  @moduledoc """
  Kaffy Tasks.
  """
  alias Usher.Config
  alias Usher.Invitation

  def task_cleanup_invitations do
    [
      %{
        name: "Cleanup Invitations",
        initial_value: nil,
        every: 50_000,
        action: fn _v ->
          import Ecto.Query

          now = DateTime.utc_now()

          from(i in Invitation, where: i.uses >= i.max_uses, select: i.id)
          |> Config.repo().update_all(set: [expires_at: now])

          from(i in Invitation, where: i.expires_at >= ^now, select: i.id)
          |> Config.repo().update_all(set: [deleted_at: now])

          {:ok, nil}
        end
      }
    ]
  end
end
