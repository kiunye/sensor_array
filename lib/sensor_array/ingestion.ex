defmodule SensorArray.Ingestion do
  @moduledoc """
  Context for ingesting data (CSV upload, store sync). Normalizes payloads,
  upserts to Postgres, and enqueues ETS rebuild per team.
  """
  alias SensorArray.Ingestion.Normalizer
  alias SensorArray.Ingestion.Upsert
  alias SensorArray.Workers.RebuildETSWorker

  @csv_source "csv"

  @doc """
  Ingest CSV rows for the given team and format.
  Format is one of "orders", "products", "customers".
  Rows is a list of maps (string keys from CSV headers).
  Returns {:ok, %{products: n, customers: n, orders: n}} or {:error, reason}.
  """
  def ingest_csv(team_id, format, rows) when format in ~w(orders products customers) and is_list(rows) do
    case normalize_and_upsert_csv(team_id, format, rows) do
      {:ok, counts} ->
        RebuildETSWorker.new(%{"team_id" => team_id}) |> Oban.insert()
        {:ok, counts}

      error ->
        error
    end
  end

  @doc """
  Ingest a batch of store-synced data (orders, products, customers) for a team.
  Data is %{orders: [...], products: [...], customers: [...]} in API-normalized form.
  Source is the store identifier (e.g. shop URL or "shopify").
  Returns {:ok, total_records} or {:error, reason}.
  """
  def ingest_store_batch(team_id, source, _store_identifier, data) when is_map(data) do
    c = upsert_customers(team_id, data)
    p = upsert_products(team_id, source, data)
    o = upsert_orders(team_id, source, data)
    {:ok, c + p + o}
  end

  defp normalize_and_upsert_csv(team_id, "products", rows) do
    attrs = Enum.map(rows, &Normalizer.to_product_attrs(&1, team_id, @csv_source))
    count = Upsert.products(team_id, attrs, @csv_source)
    {:ok, %{products: count, customers: 0, orders: 0}}
  end

  defp normalize_and_upsert_csv(team_id, "customers", rows) do
    attrs = Enum.map(rows, &Normalizer.to_customer_attrs(&1, team_id))
    count = Upsert.customers(team_id, attrs)
    {:ok, %{products: 0, customers: count, orders: 0}}
  end

  defp normalize_and_upsert_csv(team_id, "orders", rows) do
    attrs = Enum.map(rows, &Normalizer.to_order_attrs(&1, team_id, @csv_source))
    attrs_with_customer = Enum.map(attrs, fn a ->
      customer_id = resolve_customer_id(team_id, a[:customer_external_id], a[:customer_email])
      a
      |> Map.put(:customer_id, customer_id)
      |> Map.drop([:customer_email, :customer_external_id])
    end)
    count = Upsert.orders(team_id, attrs_with_customer, @csv_source)
    {:ok, %{products: 0, customers: 0, orders: count}}
  end

  defp resolve_customer_id(_team_id, nil, nil), do: nil
  defp resolve_customer_id(team_id, ext_id, _) when is_binary(ext_id) do
    Upsert.get_customer_id_by_external(team_id, ext_id)
  end
  defp resolve_customer_id(team_id, _, email) when is_binary(email) do
    Upsert.get_customer_id_by_email(team_id, email)
  end
  defp resolve_customer_id(_, _, _), do: nil

  defp upsert_customers(team_id, data) do
    attrs = Enum.map(data[:customers] || [], &Normalizer.api_customer_to_attrs(&1, team_id))
    if attrs == [], do: 0, else: Upsert.customers(team_id, attrs)
  end

  defp upsert_products(team_id, source, data) do
    attrs = Enum.map(data[:products] || [], &Normalizer.api_product_to_attrs(&1, team_id, source))
    if attrs == [], do: 0, else: Upsert.products(team_id, attrs, source)
  end

  defp upsert_orders(team_id, source, data) do
    orders = data[:orders] || []
    customer_ids = resolve_order_customer_ids(team_id, orders)
    attrs =
      Enum.zip(orders, customer_ids)
      |> Enum.map(fn {order, customer_id} ->
        Normalizer.api_order_to_attrs(order, team_id, source)
        |> Map.put(:customer_id, customer_id)
      end)
    if attrs == [], do: 0, else: Upsert.orders(team_id, attrs, source)
  end

  defp resolve_order_customer_ids(team_id, orders) do
    Enum.map(orders, fn order ->
      order = string_keys(order)
      customer = order["customer"] || order["customer_id"]
      ext_id = if is_map(customer), do: customer["id"], else: customer
      ext_id = coerce_string(ext_id)
      email = if is_map(customer), do: customer["email"], else: order["email"]
      email = coerce_string(email)
      cond do
        ext_id && ext_id != "" -> Upsert.get_customer_id_by_external(team_id, ext_id)
        email && email != "" -> Upsert.get_customer_id_by_email(team_id, email)
        true -> nil
      end
    end)
  end

  defp string_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) -> {k, (if is_map(v), do: string_keys(v), else: v)}
      {k, v} -> {to_string(k), (if is_map(v), do: string_keys(v), else: v)}
    end)
  end

  defp coerce_string(nil), do: nil
  defp coerce_string(s) when is_binary(s), do: s
  defp coerce_string(n) when is_integer(n), do: to_string(n)
  defp coerce_string(other), do: to_string(other)
end
