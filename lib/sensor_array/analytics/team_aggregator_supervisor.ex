defmodule SensorArray.Analytics.TeamAggregatorSupervisor do
  @moduledoc "DynamicSupervisor for per-team TeamAggregator GenServer processes."
  use DynamicSupervisor

  alias SensorArray.Analytics.TeamAggregator
  alias SensorArray.Analytics.TeamAggregatorRegistry

  def start_link(init_arg \\ []) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc "Returns the pid of the TeamAggregator for team_id, or nil if not started."
  def get_aggregator(team_id) do
    case Registry.lookup(TeamAggregatorRegistry, team_id) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  @doc "Starts a TeamAggregator for team_id if not already running. Returns {:ok, pid} or {:error, _}."
  def get_or_start_aggregator(team_id) do
    team_id = normalize(team_id)
    case get_aggregator(team_id) do
      nil ->
        child_spec = {TeamAggregator, team_id}
        case DynamicSupervisor.start_child(__MODULE__, child_spec) do
          {:ok, pid} -> {:ok, pid}
          {:ok, pid, _} -> {:ok, pid}
          {:error, {:already_started, pid}} -> {:ok, pid}
          err -> err
        end
      pid ->
        {:ok, pid}
    end
  end

  defp normalize(id) when is_binary(id), do: id
  defp normalize(id) when is_list(id), do: to_string(id)
  defp normalize(id), do: to_string(id)
end
