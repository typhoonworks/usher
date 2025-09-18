defmodule Usher.Kaffy.InvitationUsageAdmin do
  @moduledoc """
  Configuration for invitation usage in Kaffy admin.
  """
  import Phoenix.Component
  import Ecto.Query

  alias Usher.InvitationUsage
  alias Usher.Config

  import Usher.Utils, only: [format_date: 1]

  def custom_index_query(_conn, _schema, query) do
    from(r in query, preload: [:invitation])
  end

  def custom_show_query(_conn, _schema, query) do
    from(r in query, preload: [:invitation])
  end

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
      invitation_name: %{name: "Invitation", value: &format_name(&1.invitation.name)},
      entity_id: nil,
      entity_type: nil,
      action: nil,
      metadata: nil,
      inserted_at: %{name: "Created at", value: &format_date(&1.inserted_at)}
    ]
  end

  def format_name(name) do
    name
  end

  def form_fields(_) do
    valid_types = Config.valid_usage_entity_types()
    valid_actions = Config.valid_usage_actions()

    [
      id: %{create: :hidden, update: :hidden},
      invitation_name: %{create: :show, update: :hidden},
      entity_id: nil,
      entity_type: %{
        choices: valid_types,
        type: :array
      },
      action: %{
        choices: valid_actions,
        type: :array
      },
      metadata: nil,
      inserted_at: %{create: :hidden, update: :show}
    ]
  end

  def insert(conn, _changeset) do
    metadata = conn.params["invitation_usage"]["metadata"] |> JSON.decode!()
    action = conn.params["invitation_usage"]["action"] |> String.to_atom()
    entity_type = conn.params["invitation_usage"]["entity_type"] |> String.to_atom()
    entity_id = conn.params["invitation_usage"]["entity_id"]
    invitation_name = conn.params["invitation_usage"]["invitation_name"]

    invitation = Usher.get_invitation_by_name(invitation_name)

    case invitation do
      nil ->
        {:error, "Invitation Not Found"}

      invitation ->
        Usher.track_invitation_usage(invitation, entity_type, entity_id, action, metadata)
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
    metadata = conn.params["invitation_usage"]["metadata"] |> JSON.decode!()
    action = conn.params["invitation_usage"]["action"] |> String.to_atom()
    entity_type = conn.params["invitation_usage"]["entity_type"] |> String.to_atom()
    entity_id = conn.params["invitation_usage"]["entity_id"]

    attrs = %{
      metadata: metadata,
      action: action,
      entity_type: entity_type,
      entity_id: entity_id
    }

    entry = Usher.InvitationUsage.changeset(changeset, attrs) |> Config.repo().update()
    {:ok, entry}
  end
end
