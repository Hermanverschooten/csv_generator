# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`csv_generator` is a published Hex library (no application, no supervision tree) that provides a compile-time DSL for defining CSV layouts. Users `use CsvGenerator`, declare columns with macros, and get a generated `render/1` function on their module.

## Commands

```sh
mix deps.get
mix test                          # runs with elixirc_paths ["lib", "test"]
mix test test/csv_generator_test.exs:22   # single test by line number
mix format                        # run after every edit to an .ex/.exs file
mix docs                          # ex_doc; dev/docs env also compiles docs/
```

CI (`.github/workflows/elixir.yml`) runs only `mix test` on push/PR to `main`.

## Architecture

Everything happens at compile time in `lib/csv_generator.ex` — there is no runtime state.

1. `__using__/1` registers module attributes (`@columns` accumulating, plus `@delimiter`, `@line_ending`, `@decimal_point`, `@no_header`) and hooks `@before_compile`.
2. The DSL macros (`column/3`, `hardcoded/3`, `delimiter/1`, `line_ending/1`, `decimal_point/1`, `header/1`) only push `{name, type, opts}` tuples onto `@columns` or set a scalar attribute. Validation happens *in the macro* — invalid types/arguments `raise ArgumentError` at compile time using `__CALLER__.line`.
3. `__before_compile__/1` reads the attributes back (reversing `@columns`, since accumulate prepends) and calls `compile/5`.
4. `compile/5` builds the whole AST: a per-column `render/2` clause (from `gen_columns/2`), a static header line (`gen_header/2`), and the public `render/1` that maps rows → columns → joins.

### Name-based dispatch

Each column generates a `render(:column_name, value)` clause pattern-matched on the column's atom name. This is why:

- Column names must be unique — use `source:` to emit the same input field twice under different names/formats.
- `hardcoded/3` synthesises names like `:hardcoded0`, `:hardcoded1` from `length(@columns)`.
- Options like `format:`, `digits:`, and `decimal_point` are baked into the generated clause body, not looked up at runtime.

### The `:with` indirection

When a column has `with:`, `gen_columns/2` emits the type-specific clause as `post_render/2` instead of `render/2`, and adds a `render(name, value)` wrapper that calls the user function first, then `post_render`. Anonymous functions survive being stored in a module attribute because `column/3` `Macro.escape`s the `:with` value before accumulating it.

### Conventions in the generated code

- `nil` renders as `""` for every type except `:string`, which renders `""` (quoted empty).
- `:string` values go through `to_string/1` and have `"` doubled per RFC 4180.
- `:float` with `digits:` adds `5 / 10^(digits+2)` before `:erlang.float_to_binary/2` to force round-half-up rather than banker's rounding.
- `header/1` stores the *negation* into `@no_header` (`header false` → `@no_header true`).
- All scalar attributes use `|| default` so an explicit `nil` falls back to the default.

## Things to know when editing

- `@moduledoc File.read!("README.md")` — the README **is** the module docs. Changes to the DSL must be reflected in `README.md`, not in a separate moduledoc.
- `.formatter.exs` exports `locals_without_parens` for the DSL macros. Adding a new DSL macro means adding it there too, or user code formats badly.
- Adding a type means updating `@types`, the `case type do` in `gen_columns/2`, and the type table in `column/3`'s `@doc`.
- Bump `@version` in `mix.exs` and add a `CHANGELOG.md` entry for any released change; `package/0` `files:` controls what ships to Hex.
- `docs/example.ex` is compiled only in `:dev`/`:docs`; it exists purely to render an example page in the docs.
