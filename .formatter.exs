# SPDX-FileCopyrightText: NONE
# SPDX-License-Identifier: CC0-1.0

locals_without_parens = [field: 2, field: 3, parameter: 1, plugin: 1, plugin: 2]

[
  inputs: [
    "{mix,.check,.credo,.formatter,.iex}.exs",
    "{config,lib,scripts,test}/**/*.{ex,exs}"
  ],
  line_length: 80,
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
