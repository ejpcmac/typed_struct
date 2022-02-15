defmodule TypedStruct.MixProject do
  use Mix.Project

  @version "0.3.0"
  @repo_url "https://github.com/ejpcmac/typed_struct"

  def project do
    [
      app: :typed_struct,
      version: @version,
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Tools
      dialyzer: dialyzer(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: cli_env(),

      # Docs
      name: "TypedStruct",
      docs: [
        extras: [
          "README.md": [title: "Overview"],
          "CHANGELOG.md": [title: "Changelog"],
          "CONTRIBUTING.md": [title: "Contributing"],
          "LICENSE.md": [title: "License"]
        ],
        main: "readme",
        source_url: @repo_url,
        source_ref: "v#{@version}",
        formatters: ["html"]
      ],

      # Package
      package: package(),
      description:
        "A library for defining structs with a type without writing " <>
          "boilerplate code."
    ]
  end

  defp deps do
    [
      # Development and test dependencies
      {:ex_check, "~> 0.14.0", only: :dev, runtime: false},
      {:credo, "~> 1.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:excoveralls, ">= 0.0.0", only: :test, runtime: false},
      {:mix_test_watch, ">= 0.0.0", only: :test, runtime: false},
      {:ex_unit_notifier, ">= 0.0.0", only: :test, runtime: false},

      # Project dependencies

      # Documentation dependencies
      {:ex_doc, ">= 0.0.0", only: :docs, runtime: false}
    ]
  end

  # Dialyzer configuration
  defp dialyzer do
    [
      # Use a custom PLT directory for continuous integration caching.
      plt_core_path: System.get_env("PLT_DIR"),
      plt_file: plt_file(),
      plt_add_deps: :app_tree,
      flags: [
        :unmatched_returns,
        :error_handling,
        :race_conditions
      ],
      ignore_warnings: ".dialyzer_ignore"
    ]
  end

  defp plt_file do
    case System.get_env("PLT_DIR") do
      nil -> nil
      plt_dir -> {:no_warn, Path.join(plt_dir, "typed_struct.plt")}
    end
  end

  defp cli_env do
    [
      # Run mix test.watch in `:test` env.
      "test.watch": :test,

      # Always run Coveralls Mix tasks in `:test` env.
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.html": :test,

      # Use a custom env for docs.
      docs: :docs
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "Changelog" => "https://hexdocs.pm/typed_struct/changelog.html",
        "GitHub" => @repo_url
      }
    ]
  end

  # Helper to add a development revision to the version. Do NOT make a call to
  # Git this way in a production release!!
  def dev do
    with {rev, 0} <-
           System.cmd("git", ["rev-parse", "--short", "HEAD"],
             stderr_to_stdout: true
           ),
         {status, 0} <- System.cmd("git", ["status", "--porcelain"]) do
      status = if status == "", do: "", else: "-dirty"
      "-dev+" <> String.trim(rev) <> status
    else
      _ -> "-dev"
    end
  end
end
