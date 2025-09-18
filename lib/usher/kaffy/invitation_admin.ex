defmodule Usher.Kaffy.InvitationAdmin do
  @moduledoc """
  Configuration for invitations in Kaffy admin.
  """

  compiled =
    case Code.ensure_compiled(Phoenix.Component) do
      {:module, _} -> true
      _ -> false
    end

  if compiled == true do
    import Phoenix.Component

    alias Usher.Invitation
    alias Usher.Config

    import Usher.Utils, only: [format_date: 1]

    def widgets(_schema, _conn) do
      [
        %{
          type: "tidbit",
          title: "Total Invitations",
          content: "#{Usher.total_invitations()}",
          icon: "envelope",
          order: 1,
          width: 3
        },
        %{
          type: "tidbit",
          title: "Active Invitations",
          content: "#{Usher.total_active_invitations()}",
          icon: "envelope-open",
          order: 2,
          width: 3
        }
      ]
    end

    def index(_) do
      [
        id: nil,
        name: nil,
        token: nil,
        inserted_at: %{name: "Created at", value: &format_date(&1.inserted_at)},
        expires_at: nil,
        deleted_at: %{name: "Deleted", value: fn p -> deleted?(p) end}
      ]
    end

    def deleted?(record) do
      case record.deleted_at do
        nil -> ""
        _ -> "🗴"
      end
    end

    def form_fields(_) do
      [
        id: %{create: :hidden, update: :hidden},
        name: nil,
        description: nil,
        max_uses: nil,
        uses: nil,
        token: nil,
        inserted_at: %{create: :hidden, update: :show},
        expires_at: nil,
        deleted_at: %{create: :hidden, update: :show}
      ]
    end

    def insert(conn, _changeset) do
      name = conn.params["invitation"]["name"]
      token = conn.params["invitation"]["token"]
      expires_at = conn.params["invitation"]["expires_at"]
      description = conn.params["invitation"]["description"]
      max_uses = conn.params["invitation"]["max_uses"]
      uses = conn.params["invitation"]["uses"]

      attrs = %{
        name: name,
        token: token,
        expires_at: expires_at,
        description: description,
        max_uses: max_uses,
        uses: uses
      }

      Usher.create_invitation(attrs)
    end

    def delete(conn, _changeset) do
      with %{params: %{"ids" => id}} <- conn,
           {:ok, invitation} <- Usher.get_invitation(id),
           :ok = Usher.delete_invitation(invitation) do
        {:ok, invitation}
      else
        error ->
          {:error, error}
      end
    end

    def update(conn, changeset) do
      name = conn.params["invitation"]["name"]
      token = conn.params["invitation"]["token"]
      expires_at = conn.params["invitation"]["expires_at"]
      description = conn.params["invitation"]["description"]
      max_uses = conn.params["invitation"]["max_uses"]
      deleted_at = conn.params["invitation"]["deleted_at"]
      uses = conn.params["invitation"]["uses"]

      attrs = %{
        name: name,
        token: token,
        expires_at: expires_at,
        description: description,
        max_uses: max_uses,
        deleted_at: deleted_at,
        uses: uses
      }

      entry = Usher.Invitation.changeset(changeset, attrs) |> Config.repo().update()
      {:ok, entry}
    end
  end
end
