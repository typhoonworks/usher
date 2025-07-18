defmodule Usher.Invitations.InvitationUsageQuery do
  @moduledoc """
  Query builder for invitation usage records.
  """
  import Ecto.Query, warn: false

  alias Usher.Invitation
  alias Usher.InvitationUsage

  @doc """
  Builds a complete list query with optional filters and modifiers.

  ## Options

    * `:entity_type` - Filter by entity type (string)
    * `:action` - Filter by action (string)
    * `:limit` - Limit number of results (integer)
  """
  def list_query(%Invitation{} = invitation, opts \\ []) do
    InvitationUsage
    |> by_invitation_id(invitation)
    |> apply_entity_id_filter(opts[:entity_id])
    |> apply_entity_type_filter(opts[:entity_type])
    |> apply_action_filter(opts[:action])
    |> order_by([u], desc: u.inserted_at)
    |> apply_limit(opts[:limit])
  end

  @doc """
  Builds a unique entities query with optional filters.

  ## Options

    * `:action` - Filter by action (string)
  """
  def unique_entities_query(%Invitation{} = invitation, opts \\ []) do
    InvitationUsage
    |> by_invitation_id(invitation)
    |> apply_entity_type_filter(opts[:entity_type])
    |> apply_entity_id_filter(opts[:entity_id])
    |> apply_action_filter(opts[:action])
    |> order_by([u], desc: max(u.inserted_at))
    |> group_by([u], [u.entity_id])
    # The fragment here is a way to aggregate the usages per entity_id within an Ecto select
    # expression, when grouping by entity_id.
    |> select([u], {u.entity_id, fragment("json_agg(to_jsonb(?))", u)})
    |> apply_limit(opts[:limit])
  end

  @doc """
  Builds an existence check query for a specific entity and optional action.
  """
  def entity_exists_query(%Invitation{} = invitation, entity_type, entity_id, action \\ nil) do
    InvitationUsage
    |> by_invitation_id(invitation)
    |> apply_entity_id_filter(entity_id)
    |> apply_entity_type_filter(entity_type)
    |> apply_action_filter(action)
    |> select([u], count(u.id) > 0)
  end

  defp by_invitation_id(query, %Invitation{id: invitation_id}) do
    query
    |> where([u], u.invitation_id == ^invitation_id)
  end

  defp apply_entity_id_filter(query, nil), do: query

  defp apply_entity_id_filter(query, entity_id) when is_binary(entity_id) do
    query
    |> where([u], u.entity_id == ^entity_id)
  end

  defp apply_entity_type_filter(query, nil), do: query

  defp apply_entity_type_filter(query, entity_type) do
    query
    |> where([u], u.entity_type == ^entity_type)
  end

  defp apply_action_filter(query, nil), do: query

  defp apply_action_filter(query, action) do
    query
    |> where([u], u.action == ^action)
  end

  defp apply_limit(query, nil), do: query
  defp apply_limit(query, limit) when is_integer(limit) and limit > 0, do: limit(query, ^limit)
end
