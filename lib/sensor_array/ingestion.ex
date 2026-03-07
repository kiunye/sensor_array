defmodule SensorArray.Ingestion do
  @moduledoc """
  Context for ingesting data (CSV, store sync). Stub API until Task 3.
  """

  @doc "Ingest payload for the given team_id. Stub: always {:ok, :noop}."
  def ingest(_team_id, _payload), do: {:ok, :noop}
end
