defmodule TypedStruct.MixProject do
  use Mix.Project

  @version "0.1.1-dev"
  @repo_url "https://github.com/ejpcmac/typed_struct"

  def project do
    [
      app: :typed_struct,
      version: @version,
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Tools
      dialyzer: dialyzer(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: cli_env(),

      # Docs
      name: "TypedStruct",
      docs: [
        main: "TypedStruct",
        source_url: @repo_url,
        source_ref: "v#{@version}"
      ],

      # Package
      package: package(),
      description:
        "A library for defining structs with a type without writing " <>
          "boilerplate code."
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Development and test dependencies
      {:credo, "~> 0.9.3", only: [:dev, :test], runtime: false},
      {:dialyxir, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:excoveralls, ">= 0.0.0", only: :test, runtime: false},
      {:mix_test_watch, ">= 0.0.0", only: :dev, runtime: false},
      {:ex_unit_notifier, ">= 0.0.0", only: :test, runtime: false},

      # Project dependencies

      # Documentation dependencies
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  # Dialyzer configuration
  defp dialyzer do
    [
      plt_add_deps: :transitive,
      flags: [
        :unmatched_returns,
        :error_handling,
        :race_conditions
      ],
      ignore_warnings: ".dialyzer_ignore"
    ]
  end

  defp cli_env do
    [
      # Always run coveralls mix tasks in `:test` env.
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.html": :test
    ]
  end

  defp package do
    [
      maintainers: ["Jean-Philippe Cugnet"],
      licenses: ["MIT"],
      links: %{"GitHub" => @repo_url}
    ]
  end
end
