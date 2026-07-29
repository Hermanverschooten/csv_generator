# Changelog

## v0.3.0

* Add a `:decimal` column type, backed by the optional `:decimal` package
  (`{:decimal, "~> 3.1"}`). It rounds exactly half-up, keeps trailing zeros, and
  never emits scientific notation, unlike `:float`. Declaring a `:decimal` column
  without the package is a compile-time error; every other type is unaffected.
  3.1 is required because `Decimal.parse/1` in 2.x is subject to CVE-2026-32686.
* Passing a `Decimal` to a `:float` column now raises an error pointing at the
  `:decimal` type, instead of the generic "Invalid float value".
* Tidy the `:float` error messages: fix a "Cannort parse float value" typo, and
  stop double-quoting values that `inspect/1` already quotes.
* Fix an `ArithmeticError` when a `nil` value reached a `:float` column that had
  `digits:` set. `nil` now renders as an empty column for every type, as documented.
* Add `usage-rules.md`, describing the DSL for consuming projects.
* Fix the `README` examples: the column header option is `header:`, not `label:`.

## v0.2.1

* Update the docs canonical URL to the new per-package HexDocs subdomain style.

## v0.2.0

* Drop the `calendar` dependency in favour of the standard library `Calendar.strftime/2`.
* Requires Elixir 1.11 or later.

## v0.1.7

* Update dependencies.

## v0.1.6

* Ensure the `delimiter`, `line ending`, `decimal point`, and `header` options
  fall back to their defaults when set to `nil`.

## v0.1.5

* :string will not always convert to string

## v0.1.4

* Double the double quotes inside a string.

## v0.1.3

* Default nil values to empty columns
* Allow integer values in float columns

## v0.1.2

* add `hardcoded/3`
* add `header/1`
* Update README with formatter information
* Add exceptions

## v0.1.1

* Update documentation

* Initial release
## v0.1.0

* Initial release
