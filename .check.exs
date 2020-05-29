# Check if the version used by the runner is currently the last supported
# version, that is: the version used in the Nix shell on development machines.
last_supported_version? =
  System.version()
  |> Version.parse!()
  |> Version.match?("~> 1.10.0")

[
  skipped: false,
  tools: [
    {:compiler, "mix compile --force --verbose --warnings-as-errors"},
    {:ex_unit, "mix test --trace"},

    # Run the formatter and ex_doc only for the last supported version. This
    # avoids errors in CI when the formatting changes or ex_doc is not
    # compatible with an old Elixir version.
    {:formatter, last_supported_version?},
    {:ex_doc, last_supported_version?},

    # Check for unused dependencies in the mix.lock.
    {:unused_deps, "mix deps.unlock --check-unused",
     enabled: last_supported_version?}
  ]
]
