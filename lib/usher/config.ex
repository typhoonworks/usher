defmodule Usher.Config do
  @moduledoc """
  Configuration management for Usher.

  Handles loading and validating configuration from the application environment.
  """

  # Only introduced in Elixir 1.17 and since we support down to 1.14, we copy
  # the type definition here.
  @type duration_unit_pair() ::
          {:year, integer()}
          | {:month, integer()}
          | {:week, integer()}
          | {:day, integer()}
          | {:hour, integer()}
          | {:minute, integer()}
          | {:second, integer()}

  @type validations :: %{
          optional(:invitation) => %{name_required: boolean()},
          required(:invitation_usage) => %{
            valid_usage_entity_types: list(atom()),
            valid_usage_actions: list(atom())
          }
        }

  @type t :: [
          repo: Ecto.Repo.t(),
          token_length: non_neg_integer(),
          default_expires_in: duration_unit_pair(),
          validations: validations()
        ]

  @doc """
  Returns the configured Ecto repository.

  This is required for Usher to function and must be set in your application config:

      config :usher, repo: MyApp.Repo

  Raises if not configured.
  """
  def repo do
    case Application.get_env(:usher, :repo) do
      nil ->
        raise """
        No repo configured for Usher.

        Configure a repo in your application config:

            config :usher, repo: MyApp.Repo
        """

      repo when is_atom(repo) ->
        repo

      invalid ->
        raise """
        Invalid repo configuration for Usher: #{inspect(invalid)}

        Expected an atom (module name), got: #{inspect(invalid)}
        """
    end
  end

  @doc """
  Returns the configured token length.

  Defaults to 16 characters if not configured.
  """
  def token_length do
    Application.get_env(:usher, :token_length, 16)
  end

  @doc """
  Returns the configured default expiration duration.

  Accepts a `Duration.unit_pair()`, such as `{30, :minute}`.
  [See the docs for Duration](https://hexdocs.pm/duration/Duration.html#unit_pair/0).

  Defaults to 7 days if not configured.
  """
  def default_expires_in do
    Application.get_env(:usher, :default_expires_in, {7, :day})
  end

  @doc """
  Returns validation configuration for all schemas.
  """
  @spec validations() :: validations()
  def validations do
    Application.get_env(:usher, :validations, %{})
  end

  @doc """
  Returns whether the name field is required for invitations.

  This is a convenience function that extracts the name_required value
  from the validations configuration.
  """
  @spec name_required?() :: boolean()
  def name_required? do
    validations = validations()
    name_required = get_in(validations, [:invitation, :name_required])

    case name_required do
      name_required when is_boolean(name_required) ->
        name_required

      _ ->
        true
    end
  end

  @doc """
  Returns the configured valid entity types for invitation usage tracking.

  This is required for usage tracking to function and must be set in your application config:

      config :usher,
        validations: %{
          invitation_usage: %{
            valid_usage_entity_types: [:user, :company, :device]
          }
        }

  Raises if not configured.
  """
  def valid_usage_entity_types do
    valid_usage_entity_types =
      validations() |> get_in([:invitation_usage, :valid_usage_entity_types])

    case valid_usage_entity_types do
      nil ->
        raise """
        No valid_usage_entity_types configured for Usher.

        Configure valid entity types in your application config:

            config :usher,
              validations: %{
                invitation_usage: %{
                  valid_usage_entity_types: [:user, :company, :device]
                }
              }
        """

      types when is_list(types) ->
        if Enum.all?(types, &is_atom/1) do
          types
        else
          raise """
          Invalid valid_usage_entity_types configuration for Usher: #{inspect(types)}

          Expected a list of atoms, got: #{inspect(types)}
          """
        end

      invalid ->
        raise """
        Invalid valid_usage_entity_types configuration for Usher: #{inspect(invalid)}

        Expected a list of atoms, got: #{inspect(invalid)}
        """
    end
  end

  @doc """
  Returns the configured valid actions for invitation usage tracking.

  This is required for usage tracking to function and must be set in your application config:

      config :usher,
        validations: %{
          invitation_usage: %{
            valid_usage_actions: [:visited, :registered, :activated]
          }
        }

  Raises if not configured.
  """
  def valid_usage_actions do
    valid_usage_actions = validations() |> get_in([:invitation_usage, :valid_usage_actions])

    case valid_usage_actions do
      nil ->
        raise """
        No valid_usage_actions configured for Usher.

        Configure valid actions in your application config:

            config :usher,
              validations: %{
                invitation_usage: %{
                  valid_usage_actions: [:visited, :registered, :activated]
                }
              }
        """

      actions when is_list(actions) ->
        if Enum.all?(actions, &is_atom/1) do
          actions
        else
          raise """
          Invalid valid_usage_actions configuration for Usher: #{inspect(actions)}

          Expected a list of atoms, got: #{inspect(actions)}
          """
        end

      invalid ->
        raise """
        Invalid valid_usage_actions configuration for Usher: #{inspect(invalid)}

        Expected a list of atoms, got: #{inspect(invalid)}
        """
    end
  end

  @doc """
  Returns all Usher configuration as a keyword list.

  Useful for debugging or displaying current configuration.

  ## Examples

      iex> Usher.Config.all()
      [
        repo: MyApp.Repo,
        token_length: 16,
        default_expires_in: {7, :day},
        validations: %{
          invitation: %{name_required: true}
          invitation_usage: %{
            valid_usage_entity_types: [:user, :company],
            valid_usage_actions: [:visited, :registered]
          }
        }
      ]
  """
  @spec all() :: t()
  def all do
    [
      repo: repo(),
      token_length: token_length(),
      default_expires_in: default_expires_in(),
      validations: validations()
    ]
  end
end
