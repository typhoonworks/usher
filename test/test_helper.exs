Application.ensure_all_started(:postgrex)

Usher.Test.Repo.start_link()

ExUnit.start(exclude: [:skip])

Ecto.Adapters.SQL.Sandbox.mode(Usher.Test.Repo, :manual)
