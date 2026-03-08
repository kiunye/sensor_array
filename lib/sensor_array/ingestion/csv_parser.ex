defmodule SensorArray.Ingestion.CsvParser do
  @moduledoc "Parse CSV string to list of maps (first row = headers)."
  alias NimbleCSV.RFC4180, as: Parser

  @doc "Parse CSV string; returns list of maps with string keys from header row."
  def parse_to_maps(csv_string) when is_binary(csv_string) do
    [headers | rows] = Parser.parse_string(csv_string)
    headers = Enum.map(headers, &String.trim/1)
    Enum.map(rows, fn row ->
      row
      |> Enum.map(&String.trim/1)
      |> Enum.zip(headers)
      |> Map.new(fn {v, k} -> {k, v} end)
    end)
  end
end
