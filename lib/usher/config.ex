defmodule Usher.Config do
  @moduledoc """
  Configuration management for Usher.

  Handles loading and validating configuration from the application environment.
  """

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
  Returns the configured table name for invitations.

  Defaults to "usher_invitations" if not configured.

  ## Examples

      # Default
      iex> Usher.Config.table_name()
      "usher_invitations"

      # Configured
      config :usher, table_name: "my_invitations"
      iex> Usher.Config.table_name()
      "my_invitations"
  """
  def table_name do
    Application.get_env(:usher, :table_name, "usher_invitations")
  end

  @doc """
  Returns validation configuration for all schemas.

  Defaults to %{invitation: %{name_required: true}} if not configured.

  ## Examples

      # Default
      iex> Usher.Config.validations()
      %{invitation: %{name_required: true}}

      # Configured
      config :usher, validations: %{
        invitation: %{name_required: false}
      }
      iex> Usher.Config.validations()
      %{invitation: %{name_required: false}}
  """
  def validations do
    default_validations = %{
      invitation: %{name_required: true}
    }

    Application.get_env(:usher, :validations, default_validations)
  end

  @doc """
  Returns whether the name field is required for invitations.

  This is a convenience function that extracts the name_required value
  from the validations configuration.

  ## Examples

      # Default
      iex> Usher.Config.name_required?()
      true

      # Configured via validations
      config :usher, validations: %{
        invitation: %{name_required: false}
      }
      iex> Usher.Config.name_required?()
      false
  """
  def name_required? do
    validations()
    |> get_in([:invitation, :name_required])
    |> Kernel.||(true)
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
        table_name: "usher_invitations"
      ]
  """
  def all do
    [
      repo: repo(),
      token_length: token_length(),
      default_expires_in: default_expires_in(),
      table_name: table_name(),
      validations: validations()
    ]
  end
end
