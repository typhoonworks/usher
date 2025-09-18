# The default test configuration. Most test configurations for Usher will
# go here.
#
# Some compile-time functionality is tested using different config files.

import Config

config :usher,
  ecto_repos: [Usher.Test.Repo],
  ecto_repo: Usher.Test.Repo

config :usher, Usher.Test.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "usher_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
