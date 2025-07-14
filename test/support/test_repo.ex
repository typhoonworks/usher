defmodule Usher.Test.Repo do
  @moduledoc """
  Test repository for Usher tests.
  """
  use Ecto.Repo,
    otp_app: :usher,
    adapter: Ecto.Adapters.Postgres
end
