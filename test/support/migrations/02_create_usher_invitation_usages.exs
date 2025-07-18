defmodule Usher.Test.Repo.Migrations.CreateUsherInvitationUsages do
  use Ecto.Migration

  import Usher.Migration

  def change do
    create_usher_invitation_usages_table()
  end
end
