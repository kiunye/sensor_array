defmodule SensorArray.Workers.RebuildETSWorker do
  @moduledoc """
  Oban worker that rebuilds a team's ETS analytics table and broadcasts
  :metrics_updated. Enqueued after CSV ingest or store sync.
  """
  use Oban.Worker, queue: :default

  require Logger

  alias SensorArray.Analytics.ETSStore
  alias SensorArrayWeb.Endpoint

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"team_id" => team_id}}) do
    team_id = normalize_team_id(team_id)
    ETSStore.rebuild(team_id, placeholder: true)
    Endpoint.broadcast("team:#{team_id}", "metrics_updated", %{})
    :ok
  end

  defp normalize_team_id(id) when is_binary(id), do: id
  defp normalize_team_id(id) when is_list(id), do: to_string(id)
  defp normalize_team_id(id), do: to_string(id)
end
