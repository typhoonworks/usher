defmodule Usher.Config do
  @moduledoc """
  Configuration management for Usher.

  Handles loading and validating configuration from the application environment.

  See the [configuration guide](guides/configuration.md) for details on usage.
  """

  # Disabled because Dialyzer thinks our typespec is too broad, as it's only
  # seeing the default value returned from `Application.compile_env/3`.
  @dialyzer {:nowarn_function, schema_overrides: 0}

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

  @type invitation_token :: %{
          required(:invitation) => %{invitation_token: string()}
        }

  @type signature_token :: %{
          required(:invitation) => %{signature_token: string()}
        }

  @type schema_overrides :: %{
          optional(:invitation) => %{custom_attributes_type: :map | module()}
        }

  @type t :: [
          repo: Ecto.Repo.t(),
          token_length: non_neg_integer(),
          default_expires_in: duration_unit_pair(),
          validations: validations()
        ]

  @schema_overrides Application.compile_env(:usher, :schema_overrides, %{})

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
  Returns invitation_token configuration for all schemas.
  """
  @spec invitation_token() :: invitation_token()
  def invitation_token do
    Application.get_env(:usher, :invitation_token, "invitation_token")
  end

  @doc """
  Returns signature_token configuration for all schemas.
  """
  @spec signature_token() :: signature_token()
  def signature_token do
    Application.get_env(:usher, :signature_token, "s")
  end

  @doc """
  Returns schema override configuration for all schemas.
  """
  @spec schema_overrides() :: schema_overrides()
  def schema_overrides, do: @schema_overrides

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
  Returns the schema field type for the `:custom_attributes` field in the
  `Usher.Invitation` schema.
  """
  @spec custom_attributes_type() :: :map | module()
  def custom_attributes_type do
    custom_attributes_config_value =
      schema_overrides() |> get_in([:invitation, :custom_attributes_type])

    custom_attributes_type =
      case custom_attributes_config_value do
        nil -> :map
        module when is_atom(module) -> Code.ensure_compiled(module)
        _ -> {:error, :unsupported_config_value}
      end

    case custom_attributes_type do
      :map ->
        :map

      {:module, module} ->
        module

      {:error, :nofile} ->
        raise """
        Could not find module #{inspect(custom_attributes_config_value)}.
        """

      {:error, :unsupported_config_value} ->
        raise """
        #{inspect(custom_attributes_config_value)} is not a supported value for the `:custom_attributes_type` config.

        Must be `:map` or a module name.
        """

      error ->
        raise """
        An unexpected error occurred for `:custom_attributes_type` config value `#{inspect(custom_attributes_config_value)}`: #{inspect(error)}.
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
          },
        url_tokens: %{invitation_token: "xxx", signature_token: "xxx"}
        }
      ]
  """
  @spec all() :: t()
  def all do
    [
      repo: repo(),
      token_length: token_length(),
      default_expires_in: default_expires_in(),
      validations: validations(),
      url_tokens: %{invitation_token: invitation_token(), signature_token: signature_token()}
    ]
  end

  @doc """
  Returns the signing secret for token signing.

  Required if you use signed invitation tokens. Raises if not configured.
  """
  @spec signing_secret!() :: binary()
  def signing_secret! do
    case Application.get_env(:usher, :signing_secret) do
      secret when is_binary(secret) and byte_size(secret) > 0 ->
        secret

      nil ->
        raise """
        No signing_secret configured for Usher.

        Configure a secret in your application config to enable signing:

            config :usher, signing_secret: System.fetch_env!("USHER_SIGNING_SECRET")
        """

      other ->
        raise """
        Invalid signing_secret configuration for Usher: #{inspect(other)}

        Expected a non-empty binary, got: #{inspect(other)}
        """
    end
  end
end
