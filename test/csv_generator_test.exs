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
end
