defmodule Usher.Tasks do
  alias Usher.Config
  alias Usher.Invitation

  def task_cleanup_invitations do
    [
      %{
        name: "Cleanup Invitations",
        initial_value: nil,
        every: 50000,
        action: fn _v ->
          import Ecto.Query

          now = DateTime.utc_now()

          from(i in Invitation, where: i.expires_at >= ^now, select: i.id)
          |> Config.repo().update_all(set: [deleted_at: now])

          {:ok, nil}
        end
      }
    ]
  end
end
