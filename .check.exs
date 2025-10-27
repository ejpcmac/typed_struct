# SPDX-FileCopyrightText: 2025 Jean-Philippe Cugnet <jean-philippe@cugnet.eu>
# SPDX-License-Identifier: MIT

eclint_excluded_files = [
  "**.ex",
  "**.exs",
  "**.js",
  "**.lock",
  "**.toml",
  "LICENSES/*"
]

enabled? = fn ci_job ->
  System.get_env("CI_JOB", ci_job) == ci_job
end

[
  skipped: false,
  tools: [
    {:compiler, "mix compile --force --verbose --warnings-as-errors",
     enabled: enabled?.("checks")},

    # Commits
    {:committed, "elixir scripts/check_commits.exs",
     order: 1, enabled: enabled?.("commits")},

    # Formatters
    {:typos, "typos", order: 2, enabled: enabled?.("format")},
    {:eclint, "eclint -exclude {#{Enum.join(eclint_excluded_files, ",")}}",
     order: 3, enabled: enabled?.("format")},
    {:nixpkgs_fmt, "nixpkgs-fmt --check .",
     order: 4, enabled: enabled?.("format")},
    {:taplo, "taplo fmt --check", order: 5, enabled: enabled?.("format")},
    {:prettier, "prettier --check .", order: 6, enabled: enabled?.("format")},
    {:formatter, order: 7, enabled: enabled?.("format")},

    # Checks
    {:unused_deps, "mix deps.unlock --check-unused",
     order: 8, enabled: enabled?.("checks")},
    {:credo, order: 9, enabled: enabled?.("checks")},
    {:ex_unit, "mix test --trace", order: 10, enabled: enabled?.("checks")},
    {:ex_doc, order: 11, enabled: enabled?.("docs")},
    {:dialyzer, order: 12, enabled: enabled?.("checks")}
  ]
]
