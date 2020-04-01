This library provides an easy way to generate CSV files.
It allows you to define the colums and their respective types.

## Example

    defmodule MyCSV do
      use CsvGenerator

      column :name, :string
      column :joined, :date, format: "%d-%m-%Y"
      column :points, :integer, label: "points earned"
      hardcoded :string, "Game", "domino"
    end

You would then render the CSV bij calling the `render/1` method with
the list of lines to render.

## Example

    iex> MyCSV.render([ 
       %{ name: "Chris McCord", joined: ~D[2020-01-01], points: 110},
       %{ name: "Jose Valim", joined: ~D[2020-03-29], points: 10} ])
    "\"name\",\"joined\",\"points earned\",\"Game\"\n\"Chris McCord\",01-01-2020,110,\"domino\"\n\"Jose Valim\",29-03-2020,10,\"domino\""

By default the CSV columns will be seperated by a `","`, the lines by a `"\n"`.
This can be changed by using `delimiter` and `line_ending`.

## Example

    defmodule MyCSV do
      use CsvGenerator

      delimiter ";"
      line_ending "\r\n"

      column :name, :string
      column :birthday, :date, format: "%d-%m-%Y"
      column :points, :integer
    end

    iex> MyCSV.render([ 
       %{ name: "Jose Valim", joined: ~D[2020-03-29], points: 10} ])
    "\"name\";\"joined\";\"points earned\"\n\"Jose Valim\";29-03-2020;10"

# Formatting

A formatter is included, to be able to have `mix format` use it, you have to add it to your own `.formatter.exs` in `import_deps`.

## Example

    [
      import_deps: [:ecto, :phoenix, :csv_generator],
      inputs: ["*.{ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{ex,exs}"],
      subdirectories: ["priv/*/migrations"]
    ]
