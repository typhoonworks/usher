defmodule Mix.Tasks.Usher.CleanInvitations do
  @moduledoc """
  Mix tasks to clean Invitations.
  """

  use Mix.Task

  alias Usher.Invitation

  import Ecto.Query

  def run(_) do
    now = DateTime.utc_now()

    from(i in Invitation, where: i.uses >= i.max_uses, select: i.id)
    |> Config.repo().update_all(set: [expires_at: now])

    from(i in Invitation, where: i.expires_at >= ^now, select: i.id)
    |> Config.repo().update_all(set: [deleted_at: now])

    :ok
  end
end
