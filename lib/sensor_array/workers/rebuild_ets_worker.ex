defmodule SensorArray.Workers.RebuildETSWorker do
  @moduledoc """
  Oban worker that rebuilds a team's ETS analytics table and broadcasts
  metrics_updated. Gets or starts the per-team TeamAggregator and runs rebuild
  (Postgres → ETS → broadcast). Enqueued after CSV ingest, store sync, or when ETS keys are missing.
  """
  use Oban.Worker, queue: :default

  alias SensorArray.Analytics.TeamAggregator
  alias SensorArray.Analytics.TeamAggregatorSupervisor

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"team_id" => team_id}}) do
    team_id = normalize_team_id(team_id)
    case TeamAggregatorSupervisor.get_or_start_aggregator(team_id) do
      {:ok, _pid} ->
        TeamAggregator.rebuild(team_id)
        :ok

      {:error, _} = err ->
        err
    end
  end

  defp normalize_team_id(id) when is_binary(id), do: id
  defp normalize_team_id(id) when is_list(id), do: to_string(id)
  defp normalize_team_id(id), do: to_string(id)
end
