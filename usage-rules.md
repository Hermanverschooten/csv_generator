# CsvGenerator usage rules

`CsvGenerator` is a compile-time DSL. You `use CsvGenerator` in a module, declare
columns with macros, and the library generates a `render/1` function on that
module. There is no runtime configuration and no process to start.

```elixir
defmodule MyCSV do
  use CsvGenerator

  column :name, :string
  column :joined, :date, format: "%d-%m-%Y"
  column :points, :integer, header: "points earned"
  hardcoded :string, "Game", "domino"
end

MyCSV.render([
  %{name: "Chris McCord", joined: ~D[2020-01-01], points: 110}
])
#=> "\"name\",\"joined\",\"points earned\",\"Game\"\n\"Chris McCord\",01-01-2020,110,\"domino\""
```

`render/1` takes a **list of maps with atom keys** and returns a single string.
Structs work too. It does not write files — write the result yourself.

## Column option names

Unknown options are silently ignored — there is no validation and no warning.
A misspelled option produces a valid-looking CSV with the wrong content, so use
these exact names:

| Option | Applies to | Meaning |
| :--- | :--- | :--- |
| `:header` | all | Column header text. **Not** `:label`, `:name`, or `:title`. |
| `:format` | `:date`, `:time`, `:datetime` | `Calendar.strftime/2` format string. |
| `:digits` | `:float` | Number of decimals. |
| `:with` | all | 1-arity function applied to the value before formatting. |
| `:source` | all | Read a different key from the input map. |

## Types

| Type | Accepted values | Default format |
| :--- | :--- | :--- |
| `:string` | anything (`to_string/1` is applied) | n/a |
| `:integer` | `Integer` or `String` | n/a |
| `:float` | `Float`, `Integer`, or a parseable `String` | n/a |
| `:decimal` | `Decimal`, `Integer`, `Float`, or a parseable `String` | n/a |
| `:date` | any `Calendar.strftime/2`-compatible value | `"%Y-%m-%d"` |
| `:time` | `DateTime`, or `Integer` (unix seconds, rendered UTC) | `"%H:%M"` |
| `:datetime` | any `Calendar.strftime/2`-compatible value | `"%Y-%m-%d %H:%M:%S"` |

Any other type raises `ArgumentError` at compile time.

## Decimal support

`:decimal` needs the optional [decimal](https://hex.pm/packages/decimal)
package — add `{:decimal, "~> 3.1"}` to your own deps. Declaring a `:decimal`
column without it is a compile-time error naming the column, so you cannot
ship a broken build by accident. Every other type works with `decimal` absent.

Prefer `:decimal` over `:float` for money and for `Decimal` fields read from
Ecto. It rounds exactly half-up, keeps trailing zeros, and never emits
scientific notation — `:float` can only approximate the first and gets the
third wrong for large or tiny magnitudes. Passing a `Decimal` to a `:float`
column raises and tells you to switch.

Version 3.1 or later is required deliberately: `Decimal.parse/1` in 2.x is
subject to CVE-2026-32686 (unbounded exponent DoS), and this library calls it
on string values you supply.

CsvGenerator itself supports Elixir `~> 1.11`, but `decimal` 3.1 requires
Elixir 1.12 or later. The `:decimal` type therefore needs 1.12+, even though
every other part of the library still runs on 1.11.

## File-level settings

```elixir
delimiter ";"        # default ","
line_ending "\r\n"   # default "\n"
decimal_point ","    # default "."
header false         # default true; omits the header row
```

Each takes a binary (`header/1` takes a boolean) and raises `ArgumentError` at
compile time otherwise.

## Rules and gotchas

- **Use `:source` to emit one input field twice.** Column names become generated
  function clauses, so each must be unique. To render the same field in two
  formats, give the second column a distinct name plus `source:`:

  ```elixir
  column :points, :integer
  column :points_calc, :float, source: :points, digits: 1, with: &calc/1
  ```

- **A missing key renders as an empty column, not an error.** Values are read
  with `Map.get/2`, so a typo'd column name or absent key silently yields `nil`.
  Make sure column names match your input map's keys, or set `:source`.

- **`nil` renders as an empty column, for every type.** If you want a default
  value instead of a blank, supply one with `:with` — formatting and rounding
  are still applied to whatever it returns:

  ```elixir
  column :q, :float, digits: 1, with: fn x -> x || 0.0 end
  ```

- **`with:` runs before formatting.** `:digits`, `:format`, and `decimal_point`
  are applied to whatever your function returns, so it should return the column's
  declared type. Captures (`&calc/1`) and anonymous functions both work.

- **Strings are always quoted; embedded `"` is doubled** (RFC 4180). Other types
  are emitted bare. You do not need to escape anything yourself.

- **`hardcoded/3` is `hardcoded type, header, value`** — the header is a required
  string, and the value must already match the type. It takes no input key.

- **Everything is resolved at compile time.** Options cannot come from variables,
  application config, or function calls evaluated at runtime. To vary a delimiter
  per call, define separate modules.

- **Add `:csv_generator` to `import_deps`** in your `.formatter.exs`, or
  `mix format` will add parentheses to the DSL macros:

  ```elixir
  [import_deps: [:csv_generator], inputs: ["{lib,test}/**/*.{ex,exs}"]]
  ```
