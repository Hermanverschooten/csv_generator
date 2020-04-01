locals_without_parens = [
  delimiter: 1,
  line_ending: 1,
  decimal_point: 1,
  column: 1,
  column: 2,
  column: 3
]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
