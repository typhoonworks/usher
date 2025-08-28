defmodule Usher.MixProject do
  use Mix.Project

  @version "0.4.0"
  @source_url "https://github.com/typhoonworks/usher"

  @test_environments [:test, :test_custom_attributes_embedded_schema]

  def project do
    [
      app: :usher,
      name: "Usher",
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: docs(),
      package: package(),
      description: description(),
      source_url: @source_url,
      homepage_url: @source_url,
      dialyzer: dialyzer()
    ]
  end

  def cli do
    [preferred_envs: ["test.setup": :test, test: :test]]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test_custom_attributes_embedded_schema), do: ["lib", "test/support"]
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ecto, "~> 3.13"},
      {:ecto_sql, "~> 3.13"},
      {:jason, "~> 1.4", optional: true},
      {:postgrex, "~> 0.20", optional: true},

      # Development and testing dependencies
      {:dialyxir, "~> 1.4", only: [:dev | @test_environments], runtime: false},
      {:ex_doc, "~> 0.38", only: [:dev | @test_environments], runtime: false},
      {:mimic, "~> 2.0", only: @test_environments}
    ]
  end

  defp aliases do
    [
      test: ["test --exclude custom_attributes_embedded_schema"],
      "test.custom_attributes": [
        fn _ ->
          Mix.shell().cmd(
            "mix test --only custom_attributes_embedded_schema",
            env: [{"MIX_ENV", "test_custom_attributes_embedded_schema"}],
            stderr_to_stdout: false
          )
        end
      ],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "test.setup": ["ecto.drop --quiet", "ecto.create", "ecto.migrate"],
      lint: ["format", "dialyzer"]
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: docs_guides(),
      groups_for_modules: [
        Core: [Usher, Usher.Config],
        Schema: [Usher.Invitation, Usher.InvitationUsage, Usher.Types.Atom],
        Migrations: [Usher.Migration, ~r/Usher\.Migrations\..+/],
        Context: [~r/Usher\.Invitations\..+/]
      ]
    ]
  end

  defp docs_guides do
    [
      "README.md",
      "guides/overview.md",
      "guides/installation.md",
      "guides/getting-started.md",
      "guides/advanced-usage.md",
      "guides/invitation-usage-tracking.md",
      "guides/phoenix-integration.md",
      "guides/configuration.md",
      "guides/testing.md",
      "guides/contributing.md"
    ]
  end

  defp package do
    [
      name: "usher",
      maintainers: ["Arda Can Tugay", "Rui Freitas"],
      licenses: ["MIT"],
      links: %{GitHub: @source_url},
      files: ~w[lib .formatter.exs mix.exs README* LICENSE*]
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:mix, :ecto, :postgrex, :ex_unit],
      plt_core_path: "_build/#{Mix.env()}",
      flags: [:error_handling, :underspecs, :missing_return]
    ]
  end

  defp description do
    """
    Usher provides framework-agnostic invitation link management for any Elixir application with Ecto.
    """
  end
end
