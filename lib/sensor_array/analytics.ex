defmodule SensorArray.Analytics do
  @moduledoc """
  Context for aggregated metrics (sales, products, inventory, funnel, segments).
  Stub API until Task 4; reads from ETSStore when implemented.
  """

  @doc "Returns metrics for the given team_id. Stub: reads from ETSStore or empty map."
  def get_metrics(team_id) do
    case Process.whereis(SensorArray.Analytics.ETSStore) do
      nil -> %{}
      _ -> SensorArray.Analytics.ETSStore.get_metrics(team_id)
    end
  end
end
