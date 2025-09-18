# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

config :logger, level: :warning

config :usher, ecto_repos: [Usher.Test.Repo]

config :usher,
  repo: Usher.Test.Repo,
  token_length: 16,
  default_expires_in: {7, :day},
  validations: %{
    invitation_usage: %{
      valid_usage_entity_types: [:user, :company, :device],
      valid_usage_actions: [:visited, :registered, :activated]
    }
  },
  signing_secret: "test-secret",
  invitation_token: "invitation_token",
  signature_token: "s"

config :usher, Usher.Test.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 2345,
  database: "usher_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2,
  priv: "test/support",
  show_sensitive_data_on_connection_error: true,
  stacktrace: true

config :kaffy,
  otp_app: :usher,
  ecto_repo: Usher.Test.Repo,
  router: Usher.Test.Router,
  resources: &Usher.Kaffy.Config.create_resources/1,
  scheduled_tasks: [
    Usher.Tasks
  ]

import_config "#{config_env()}.exs"
