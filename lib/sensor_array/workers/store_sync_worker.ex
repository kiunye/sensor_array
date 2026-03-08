defmodule SensorArray.Workers.StoreSyncWorker do
  @moduledoc """
  Single Oban worker run hourly. Loads all store connections, fetches
  orders/products/customers per connection (Shopify or WooCommerce),
  normalizes and upserts, writes sync_logs, and enqueues RebuildETSWorker per team.
  """
  use Oban.Worker, queue: :sync

  require Logger

  @impl Oban.Worker
  def perform(_job) do
    case SensorArray.Integrations.list_all_connections() do
      {:ok, connections} ->
        Enum.each(connections, &sync_connection/1)
        :ok

      {:error, reason} ->
        Logger.error("StoreSyncWorker: failed to list connections: #{inspect(reason)}")
        :ok
    end
  end

  defp sync_connection(conn) do
    team_id = conn.team_id
    case do_sync(conn) do
      {:ok, records_synced} ->
        SensorArray.Integrations.log_sync(conn.id, team_id, "success", records_synced, nil)
        SensorArray.Workers.RebuildETSWorker.new(%{"team_id" => team_id}) |> Oban.insert()

      {:error, reason} ->
        msg = if is_binary(reason), do: reason, else: inspect(reason)
        SensorArray.Integrations.log_sync(conn.id, team_id, "error", 0, msg)
        Logger.warning("StoreSyncWorker: sync failed for connection #{conn.id}: #{msg}")
    end
  end

  defp do_sync(%{platform: "shopify"} = conn) do
    case SensorArray.Integrations.ShopifyClient.fetch_all(conn) do
      {:ok, data} -> SensorArray.Ingestion.ingest_store_batch(conn.team_id, "shopify", conn.shop_url, data)
      err -> err
    end
  end

  defp do_sync(%{platform: "woocommerce"} = conn) do
    case SensorArray.Integrations.WooCommerceClient.fetch_all(conn) do
      {:ok, data} -> SensorArray.Ingestion.ingest_store_batch(conn.team_id, "woocommerce", conn.shop_url, data)
      err -> err
    end
  end
end
