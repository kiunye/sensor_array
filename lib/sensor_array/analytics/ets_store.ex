defmodule SensorArray.Analytics.ETSStore do
  @moduledoc """
  Per-team ETS table lifecycle: create, rebuild, and read.
  One named table per team (e.g. :"analytics_<team_id>") holds
  aggregated metrics for the dashboard. Rebuild clears and repopulates
  from Postgres or placeholder data; used by ingestion and sync.
  """
  use GenServer

  require Logger

  @doc "Start the ETS manager (singleton)."
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Ensure a table exists for the given team_id (binary or string UUID)."
  def ensure_table(team_id) do
    GenServer.call(__MODULE__, {:ensure_table, normalize_id(team_id)})
  end

  @doc "Rebuild the team's ETS table: delete if present, create fresh, optionally with placeholder keys."
  def rebuild(team_id, opts \\ []) do
    GenServer.call(__MODULE__, {:rebuild, normalize_id(team_id), opts})
  end

  @doc "Read metrics for a team. Returns a map of key -> value or empty map if table missing."
  def get_metrics(team_id) do
    GenServer.call(__MODULE__, {:get_metrics, normalize_id(team_id)})
  end

  @doc "Look up a single key for a team."
  def get(team_id, key) do
    GenServer.call(__MODULE__, {:get, normalize_id(team_id), key})
  end

  @doc "Insert a key/value into the team's table (for use by aggregator)."
  def put(team_id, key, value) do
    GenServer.call(__MODULE__, {:put, normalize_id(team_id), key, value})
  end

  # GenServer callbacks
  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:ensure_table, team_id}, _from, state) do
    table = table_name(team_id)
    result =
      case :ets.whereis(table) do
        :undefined ->
          tid = :ets.new(table, [:set, :public, :named_table])
          {:ok, tid}

        tid when is_integer(tid) ->
          {:ok, tid}
      end

    {:reply, result, state}
  end

  @impl true
  def handle_call({:rebuild, team_id, opts}, _from, state) do
    table = table_name(team_id)
    if :ets.whereis(table) != :undefined do
      :ets.delete(table)
    end

    tid = :ets.new(table, [:set, :public, :named_table])

    if Keyword.get(opts, :placeholder, false) do
      write_placeholder_keys(tid)
    end

    {:reply, {:ok, tid}, state}
  end

  @impl true
  def handle_call({:get_metrics, team_id}, _from, state) do
    table = table_name(team_id)
    result =
      case :ets.whereis(table) do
        :undefined -> %{}
        _ ->
          :ets.tab2list(table)
          |> Enum.into(%{}, fn {k, v} -> {k, v} end)
      end

    {:reply, result, state}
  end

  @impl true
  def handle_call({:get, team_id, key}, _from, state) do
    table = table_name(team_id)
    result =
      case :ets.whereis(table) do
        :undefined -> nil
        _ ->
          case :ets.lookup(table, key) do
            [{^key, value}] -> value
            [] -> nil
          end
      end

    {:reply, result, state}
  end

  @impl true
  def handle_call({:put, team_id, key, value}, _from, state) do
    table = table_name(team_id)
    case :ets.whereis(table) do
      :undefined ->
        :ets.new(table, [:set, :public, :named_table])
        :ets.insert(table, {key, value})
        {:reply, :ok, state}
      _ ->
        :ets.insert(table, {key, value})
        {:reply, :ok, state}
    end
  end

  defp table_name(team_id), do: :"analytics_#{team_id}"

  defp normalize_id(id) when is_binary(id), do: id
  defp normalize_id(id) when is_list(id), do: to_string(id)
  defp normalize_id(id), do: to_string(id)

  defp write_placeholder_keys(tid) do
    :ets.insert(tid, {{:sales_trend, :daily}, []})
    :ets.insert(tid, {{:sales_trend, :weekly}, []})
    :ets.insert(tid, {{:sales_trend, :monthly}, []})
    :ets.insert(tid, {{:top_products, :revenue}, []})
    :ets.insert(tid, {:inventory_alerts, []})
    :ets.insert(tid, {:funnel, %{viewed: 0, added_to_cart: 0, checkout: 0, purchased: 0}})
    :ets.insert(tid, {:segments, %{new: 0, returning: 0, at_risk: 0, champions: 0}})
  end
end
