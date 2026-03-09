defmodule SensorArray.Analytics.TeamAggregator do
  @moduledoc """
  Per-team GenServer that owns aggregation from Postgres and write-through to ETS.
  Rebuild: clear ETS table, compute all metrics, put into ETS, broadcast metrics_updated.
  """
  use GenServer

  require Logger

  alias SensorArray.Analytics.ETSStore
  alias SensorArray.Analytics.Aggregations
  alias SensorArray.Analytics.TeamAggregatorRegistry
  alias SensorArrayWeb.Endpoint

  def start_link(team_id) do
    team_id = normalize(team_id)
    GenServer.start_link(__MODULE__, team_id, name: via(team_id))
  end

  @doc "Trigger full rebuild: Postgres → ETS, then broadcast."
  def rebuild(team_id) do
    team_id = normalize(team_id)
    case GenServer.call(via(team_id), :rebuild, 60_000) do
      :ok -> :ok
      {:error, _} = err -> err
    end
  end

  defp via(team_id), do: {:via, Registry, {TeamAggregatorRegistry, team_id}}

  @impl true
  def init(team_id) do
    Registry.register(TeamAggregatorRegistry, team_id, nil)
    {:ok, %{team_id: team_id}}
  end

  @impl true
  def handle_call(:rebuild, _from, %{team_id: team_id} = state) do
    try do
      # Clear and create empty ETS table (no placeholders)
      ETSStore.rebuild(team_id, [])

      # Compute and write each key
      ETSStore.put(team_id, {:sales_trend, :daily}, Aggregations.sales_trend_daily(team_id))
      ETSStore.put(team_id, {:sales_trend, :weekly}, Aggregations.sales_trend_weekly(team_id))
      ETSStore.put(team_id, {:sales_trend, :monthly}, Aggregations.sales_trend_monthly(team_id))
      ETSStore.put(team_id, {:top_products, :revenue}, Aggregations.top_products_revenue(team_id))
      ETSStore.put(team_id, :inventory_alerts, Aggregations.inventory_alerts(team_id))
      ETSStore.put(team_id, :funnel, Aggregations.funnel(team_id))
      ETSStore.put(team_id, :segments, Aggregations.segments(team_id))

      Endpoint.broadcast("team:#{team_id}", "metrics_updated", %{})
      {:reply, :ok, state}
    rescue
      e ->
        Logger.error("TeamAggregator rebuild failed for #{team_id}: #{inspect(e)}")
        {:reply, {:error, e}, state}
    end
  end

  defp normalize(id) when is_binary(id), do: id
  defp normalize(id) when is_list(id), do: to_string(id)
  defp normalize(id), do: to_string(id)
end
