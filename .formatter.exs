locals_without_parens = [field: 2, field: 3, plugin: 1, plugin: 2]

[
  inputs: [
    "{mix,.iex,.formatter,.credo}.exs",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  line_length: 80,
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
