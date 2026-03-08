defmodule SensorArray.Workers.StoreSyncWorker do
  @moduledoc """
  Single Oban worker run hourly. Loads all store connections, fetches
  orders/products/customers per connection (Shopify or WooCommerce),
  normalizes and upserts, writes sync_logs, and enqueues RebuildETSWorker per team.
  """
  use Oban.Worker, queue: :sync

  require Logger

  alias SensorArray.Ingestion
  alias SensorArray.Integrations
  alias SensorArray.Integrations.ShopifyClient
  alias SensorArray.Integrations.WooCommerceClient
  alias SensorArray.Workers.RebuildETSWorker

  @impl Oban.Worker
  def perform(_job) do
    case Integrations.list_all_connections() do
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
        Integrations.log_sync(conn.id, team_id, "success", records_synced, nil)
        RebuildETSWorker.new(%{"team_id" => team_id}) |> Oban.insert()

      {:error, reason} ->
        msg = if is_binary(reason), do: reason, else: inspect(reason)
        Integrations.log_sync(conn.id, team_id, "error", 0, msg)
        Logger.warning("StoreSyncWorker: sync failed for connection #{conn.id}: #{msg}")
    end
  end

  defp do_sync(%{platform: "shopify"} = conn) do
    case ShopifyClient.fetch_all(conn) do
      {:ok, data} -> Ingestion.ingest_store_batch(conn.team_id, "shopify", conn.shop_url, data)
      err -> err
    end
  end

  defp do_sync(%{platform: "woocommerce"} = conn) do
    case WooCommerceClient.fetch_all(conn) do
      {:ok, data} -> Ingestion.ingest_store_batch(conn.team_id, "woocommerce", conn.shop_url, data)
      err -> err
    end
  end
end
