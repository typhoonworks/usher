defmodule Usher.Kaffy.InvitationUsageAdmin do
  @moduledoc """
  Configuration for invitation usage in Kaffy admin.
  """
  import Phoenix.Component

  alias Usher.InvitationUsage

  import Usher.Utils, only: [format_date: 1]

  def widgets(_schema, _conn) do
    [
      %{
        type: "tidbit",
        title: "Total Invitation Usages",
        content: "#{Usher.total_invitation_usages()}",
        icon: "inbox-stack",
        order: 1,
        width: 3
      }
    ]
  end

  def index(_) do
    [
      id: nil,
      invitation_name: %{name: "Invitation Name"},
      entity_type: nil,
      action: nil,
      metadata: nil,
      inserted_at: %{name: "Created at", value: &format_date(&1.inserted_at)}
    ]
  end

  def form_fields(_) do
    [
      id: %{create: :hidden, update: :show},
      invitation_name: nil,
      entity_type: nil,
      action: nil,
      metadata: nil,
      inserted_at: %{create: :hidden, update: :show}
    ]
  end

  def insert(conn, _changeset) do
    metadata = conn.params["invitation_usage"]["metadata"]
    action = conn.params["invitation_usage"]["action"]
    entity_type = conn.params["invitation_usage"]["entity_type"]
    entity_id = conn.params["invitation_usage"]["entity_id"]
    invitation_name = conn.params["invitation_usage"]["invitation_name"]

    {status, invitation} = Usher.get_invitation_by_name(invitation_name)

    case status do
      :ok -> Usher.track_invitation_usage(invitation, entity_type, entity_id, action, metadata)
      :error -> {status, invitation}
    end
  end

  def delete(conn, _changeset) do
    with %{params: %{"ids" => id}} <- conn,
         {:ok, invitation} <- Usher.get_invitation_usage(id),
         :ok = Usher.delete_invitation_usage(invitation) do
      {:ok, invitation}
    else
      error ->
        {:error, error}
    end
  end

  def update(conn, changeset) do
    metadata = conn.params["invitation_usage"]["metadata"]
    action = conn.params["invitation_usage"]["action"]
    entity_type = conn.params["invitation_usage"]["entity_type"]
    entity_id = conn.params["invitation_usage"]["entity_id"]

    attrs = %{
      "metadata" => metadata,
      "action" => action,
      "entity_type" => entity_type,
      "entity_id" => entity_id
    }

    entry = Usher.InvitationUsage.changeset(changeset, attrs) |> Config.repo().update()
    {:ok, entry}
  end
end
