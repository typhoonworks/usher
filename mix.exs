defmodule Usher.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :usher,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: docs(),
      package: package(),
      description: description(),
      source_url: "https://github.com/typhoonworks/usher",
      homepage_url: "https://github.com/typhoonworks/usher",

      dialyzer: [
        plt_add_apps: [:mix, :ecto, :postgrex, :ex_unit],
        plt_core_path: "_build/#{Mix.env()}",
        flags: [:error_handling, :underspecs, :missing_return, :unmatched_returns]
      ]
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

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ecto, "~> 3.13"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, "~> 0.20", optional: true},
      {:ex_doc, "~> 0.38", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
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
      extras: ["README.md"],
      groups_for_modules: [
        Core: [Usher, Usher.Config],
        Schema: [Usher.Invitation],
        Integrations: [Usher.Phoenix]
      ]
    ]
  end

  defp package do
    [
      maintainers: ["Arda Can Tugay", "Rui Freitas"],
      licenses: ["MIT"],
      links: %{GitHub: "https://github.com/typhoonworks/usher"},
      files: ~w[lib .formatter.exs mix.exs README.md LICENSE.md]
    ]
  end

  defp description do
    """
    Usher provides framework-agnostic invitation link management for any Elixir application with Ecto.
    """
  end
end
