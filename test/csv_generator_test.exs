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

  defmodule DecimalCSV do
    use CsvGenerator

    header false

    column :plain, :decimal
    column :rounded, :decimal, digits: 2
  end

  defmodule DecimalCommaCSV do
    use CsvGenerator

    header false
    delimiter ";"
    decimal_point ","

    column :plain, :decimal
    column :rounded, :decimal, digits: 2
  end

  defmodule FloatCSV do
    use CsvGenerator

    header false

    column :f, :float
  end

  describe "decimal columns" do
    test "render Decimal values, rounding half-up to the requested digits" do
      row = %{plain: Decimal.new("1.5"), rounded: Decimal.new("1.255")}
      assert DecimalCSV.render([row]) == "1.5,1.26"
    end

    test "keep trailing zeros up to the requested digits" do
      assert DecimalCSV.render([%{plain: Decimal.new("2"), rounded: Decimal.new("0.1")}]) ==
               "2,0.10"
    end

    test "never emit scientific notation" do
      assert DecimalCSV.render([%{plain: Decimal.new("1E3"), rounded: Decimal.new("1E3")}]) ==
               "1000,1000.00"
    end

    test "honour the configured decimal point" do
      assert DecimalCommaCSV.render([%{plain: Decimal.new("1.5"), rounded: Decimal.new("1.255")}]) ==
               "1,5;1,26"
    end

    test "accept integers, floats and strings" do
      assert DecimalCSV.render([%{plain: 10, rounded: 10}]) == "10,10.00"
      assert DecimalCSV.render([%{plain: 1.5, rounded: 1.5}]) == "1.5,1.50"
      assert DecimalCSV.render([%{plain: "1.5", rounded: "1.255"}]) == "1.5,1.26"
    end

    test "render nil as an empty column" do
      assert DecimalCSV.render([%{}]) == ","
    end

    test "raise on unparseable strings and unsupported values" do
      assert_raise RuntimeError, ~r/Cannot parse decimal value/, fn ->
        DecimalCSV.render([%{plain: "abc"}])
      end

      assert_raise RuntimeError, ~r/Cannot parse decimal value/, fn ->
        DecimalCSV.render([%{plain: "1.5abc"}])
      end

      assert_raise RuntimeError, ~r/Invalid decimal value/, fn ->
        DecimalCSV.render([%{plain: :nope}])
      end
    end

    test "reject unbounded exponents rather than expanding them (CVE-2026-32686)" do
      assert_raise RuntimeError, ~r/Cannot parse decimal value/, fn ->
        DecimalCSV.render([%{plain: "1e1000000000"}])
      end
    end

    test "a Decimal in a :float column points at the :decimal type" do
      assert_raise RuntimeError, ~r/use the :decimal column type/, fn ->
        FloatCSV.render([%{f: Decimal.new("1.5")}])
      end
    end
  end

  describe "float column errors" do
    test "report unparseable strings, quoted once" do
      assert_raise RuntimeError, ~s(Cannot parse float value "abc"), fn ->
        FloatCSV.render([%{f: "abc"}])
      end
    end

    test "report unsupported values" do
      assert_raise RuntimeError, "Invalid float value :nope", fn ->
        FloatCSV.render([%{f: :nope}])
      end
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
