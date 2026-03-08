defmodule SensorArray.Integrations do
  @moduledoc """
  Context for store connections (Shopify, WooCommerce) and sync logs.
  """
  alias SensorArray.Integrations.StoreConnection
  alias SensorArray.Repo

  import Ecto.Query

  @doc "Returns store connections for the given team_id."
  def list_connections(team_id) do
    connections =
      StoreConnection
      |> where([c], c.team_id == ^team_id)
      |> order_by([c], asc: c.inserted_at)
      |> Repo.all()

    {:ok, connections}
  end

  @doc "Returns the connection for the given id, or {:error, :not_found}."
  def get_connection(id) do
    case Repo.get(StoreConnection, id) do
      nil -> {:error, :not_found}
      conn -> {:ok, conn}
    end
  end

  @doc "Returns the connection for the given id and team_id (team-scoped)."
  def get_connection_for_team(id, team_id) do
    case Repo.get_by(StoreConnection, id: id, team_id: team_id) do
      nil -> {:error, :not_found}
      conn -> {:ok, conn}
    end
  end

  @doc "Returns all store connections (for hourly sync worker)."
  def list_all_connections do
    connections =
      StoreConnection
      |> order_by([c], asc: c.team_id, asc: c.inserted_at)
      |> Repo.all()

    {:ok, connections}
  end

  @doc "Creates a sync log entry for a connection."
  def log_sync(connection_id, team_id, status, records_synced, error) do
    %SensorArray.Integrations.SyncLog{
      team_id: team_id,
      connection_id: connection_id,
      status: status,
      records_synced: records_synced || 0,
      error: error,
      completed_at: DateTime.utc_now()
    }
    |> Repo.insert()
  end
end
