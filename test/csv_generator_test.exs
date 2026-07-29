defmodule CsvGeneratorTest do
  use ExUnit.Case

  defmodule MyCSV do
    use CsvGenerator

    header true

    column :name, :string, header: "player"
    column :points, :integer
    column :calculated, :float, digits: 1, source: :points, with: &calc/1
    hardcoded :date, "today", ~D[2020-03-29]
    column :hour, :time
    column :q, :float, with: fn x -> if x == nil, do: 0.0, else: x end, digits: 1
    column :d, :float, digits: 2

    def calc(pt) do
      1000 / pt
    end
  end

  test "rendering" do
    assert MyCSV.render([
             %{name: "Herman", points: 122, hour: 7200, d: 1.255},
             %{name: "Jose", points: 902, hour: 34231, q: 0.192, d: 0.1},
             %{name: "3.5\" monitor", points: 902, hour: 34231, q: 0.192, d: 0.1},
             %{name: nil, points: 902, hour: 34231, q: 0.192, d: 0.1}
           ]) ==
             """
             "player","points","calculated","today","hour","q","d"
             "Herman",122,8.2,2020-03-29,02:00,0.0,1.26
             "Jose",902,1.1,2020-03-29,09:30,0.2,0.10
             "3.5\"\" monitor",902,1.1,2020-03-29,09:30,0.2,0.10
             "",902,1.1,2020-03-29,09:30,0.2,0.10\
             """
  end

  defmodule NilFloatCSV do
    use CsvGenerator

    header false

    column :plain, :float
    column :rounded, :float, digits: 2
  end

  defmodule NilFloatCommaCSV do
    use CsvGenerator

    header false
    delimiter ";"
    decimal_point ","

    column :plain, :float
    column :rounded, :float, digits: 2
  end

  describe "nil values in float columns" do
    test "render as an empty column, with and without digits" do
      assert NilFloatCSV.render([%{plain: nil, rounded: nil}]) == ","
    end

    test "render as an empty column when the key is absent entirely" do
      assert NilFloatCSV.render([%{}]) == ","
    end

    test "render as an empty column with a custom decimal point" do
      assert NilFloatCommaCSV.render([%{}]) == ";"
    end

    test "do not affect non-nil values in the same column" do
      assert NilFloatCSV.render([%{plain: 1.5, rounded: 1.255}, %{}]) == "1.5,1.26\n,"
      assert NilFloatCommaCSV.render([%{plain: 1.5, rounded: 1.255}]) == "1,5;1,26"
    end
  end

  defmodule ReadmeExample1 do
    use CsvGenerator

    column :name, :string
    column :joined, :date, format: "%d-%m-%Y"
    column :points, :integer, header: "points earned"
    hardcoded :string, "Game", "domino"
  end

  defmodule ReadmeExample2 do
    use CsvGenerator

    delimiter ";"
    line_ending "\r\n"

    column :name, :string
    column :joined, :date, format: "%d-%m-%Y"
    column :points, :integer, header: "points earned"
  end

  describe "README examples" do
    test "first example renders exactly as documented" do
      assert ReadmeExample1.render([
               %{name: "Chris McCord", joined: ~D[2020-01-01], points: 110},
               %{name: "Jose Valim", joined: ~D[2020-03-29], points: 10}
             ]) ==
               "\"name\",\"joined\",\"points earned\",\"Game\"\n\"Chris McCord\",01-01-2020,110,\"domino\"\n\"Jose Valim\",29-03-2020,10,\"domino\""
    end

    test "second example renders exactly as documented" do
      assert ReadmeExample2.render([
               %{name: "Jose Valim", joined: ~D[2020-03-29], points: 10}
             ]) == "\"name\";\"joined\";\"points earned\"\r\n\"Jose Valim\";29-03-2020;10"
    end
  end
end
