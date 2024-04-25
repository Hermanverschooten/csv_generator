defmodule CsvGenerator.MixProject do
  use Mix.Project

  @version "0.1.7"

  def project do
    [
      app: :csv_generator,
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "CsvGenerator",
      docs: docs(),
      elixirc_paths: paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:calendar, "~> 1.0"},
      {:ex_doc, "~> 0.20", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    Library to help you generate CSV files
    """
  end

  defp package do
    [
      maintainers: ["Herman verschooten"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/Hermanverschooten/csv_generator"},
      files: ~w(.formatter.exs mix.exs README.md CHANGELOG.md lib)
    ]
  end

  defp docs do
    [
      main: "CsvGenerator",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/csv_generator",
      source_url: "https://github.com/Hermanverschooten/csv_generator"
    ]
  end

  defp paths(:test), do: ["lib", "test"]
  defp paths(:dev), do: ["lib", "docs"]
  defp paths(:docs), do: ["lib", "docs"]
  defp paths(_), do: ["lib"]
end
