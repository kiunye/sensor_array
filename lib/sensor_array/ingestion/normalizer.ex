defmodule SensorArray.Ingestion.Normalizer do
  @moduledoc """
  Maps CSV rows (and API payloads) to unified schema attrs for Order, Product, Customer.
  Supports multiple column naming conventions (case-insensitive, underscores).
  """

  @doc "Normalize a single row to product attrs. Row is a map with string keys."
  def to_product_attrs(row, team_id, source) when is_map(row) do
    row = string_key_map(row)
    %{
      team_id: team_id,
      external_id: get(row, ~w(id external_id product_id)),
      source: source,
      name: get(row, ~w(name title product_name)) || "Unknown",
      sku: get(row, ~w(sku)),
      price: parse_decimal(get(row, ~w(price unit_price))),
      stock_quantity: parse_int(get(row, ~w(stock_quantity stock quantity)), 0),
      low_stock_threshold: parse_int(get(row, ~w(low_stock_threshold threshold)), 10)
    }
  end

  @doc "Normalize a single row to customer attrs."
  def to_customer_attrs(row, team_id) when is_map(row) do
    row = string_key_map(row)
    %{
      team_id: team_id,
      external_id: get(row, ~w(id external_id customer_id)),
      email: get(row, ~w(email)),
      first_name: get(row, ~w(first_name firstname first)),
      last_name: get(row, ~w(last_name lastname last)),
      total_spent: parse_decimal(get(row, ~w(total_spent total_spend)), 0),
      order_count: parse_int(get(row, ~w(order_count orders_count)), 0),
      last_ordered_at: parse_datetime(get(row, ~w(last_ordered_at last_order_at))),
      segment: get(row, ~w(segment))
    }
  end

  @doc "Normalize a single row to order attrs. Optional :customer_email or :customer_external_id for lookup; caller resolves customer_id."
  def to_order_attrs(row, team_id, source) when is_map(row) do
    row = string_key_map(row)
    %{
      team_id: team_id,
      external_id: get(row, ~w(id order_id external_id)),
      source: source,
      status: get(row, ~w(status)) || "unknown",
      total: parse_decimal(get(row, ~w(total total_amount amount)), 0),
      currency: get(row, ~w(currency)) || "USD",
      ordered_at: parse_datetime(get(row, ~w(ordered_at order_date created_at date))),
      customer_id: nil,
      customer_email: get(row, ~w(customer_email email)),
      customer_external_id: get(row, ~w(customer_id customer_external_id))
    }
  end

  @doc "Normalize API payload (e.g. Shopify order) to our order attrs. customer_id resolved separately."
  def api_order_to_attrs(api_order, team_id, source) when is_map(api_order) do
    row = string_key_map(api_order)
    %{
      team_id: team_id,
      external_id: to_external_id(get(row, ~w(id order_number))),
      source: source,
      status: normalize_status(get(row, ~w(status financial_status))),
      total: parse_decimal(get(row, ~w(total_price total total_amount)), 0),
      currency: get(row, ~w(currency)) || "USD",
      ordered_at: parse_datetime(get(row, ~w(created_at order_date processed_at))),
      customer_id: nil
    }
  end

  @doc "Normalize API payload to product attrs."
  def api_product_to_attrs(api_product, team_id, source) when is_map(api_product) do
    row = string_key_map(api_product)
    variants = get(row, ~w(variants)) || []
    first_variant = List.first(variants)
    first_variant = if is_map(first_variant), do: string_key_map(first_variant), else: %{}
    price = parse_decimal(get(row, ~w(price)) || get(first_variant, ~w(price)))
    %{
      team_id: team_id,
      external_id: to_external_id(get(row, ~w(id))),
      source: source,
      name: get(row, ~w(title name)) || "Unknown",
      sku: get(row, ~w(sku)) || get(first_variant, ~w(sku)),
      price: price,
      stock_quantity: parse_int(get(row, ~w(inventory_quantity total_inventory)), 0),
      low_stock_threshold: 10
    }
  end

  @doc "Normalize API payload to customer attrs."
  def api_customer_to_attrs(api_customer, team_id) when is_map(api_customer) do
    row = string_key_map(api_customer)
    %{
      team_id: team_id,
      external_id: to_external_id(get(row, ~w(id))),
      email: get(row, ~w(email)),
      first_name: get(row, ~w(first_name firstname)),
      last_name: get(row, ~w(last_name lastname)),
      total_spent: parse_decimal(get(row, ~w(total_spent)), 0),
      order_count: parse_int(get(row, ~w(orders_count)), 0),
      last_ordered_at: parse_datetime(get(row, ~w(last_order_date))),
      segment: nil
    }
  end

  defp get(row, keys) when is_map(row) do
    row_lower = Map.new(row, fn {k, v} -> {String.downcase(to_string(k)), v} end)
    Enum.find_value(keys, fn k ->
      v = Map.get(row_lower, String.downcase(to_string(k)))
      if is_binary(v), do: String.trim(v), else: v
    end)
  end

  defp string_key_map(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) -> {k, string_key_value(v)}
      {k, v} -> {to_string(k), string_key_value(v)}
    end)
  end

  defp string_key_value(list) when is_list(list), do: Enum.map(list, &string_key_value/1)
  defp string_key_value(map) when is_map(map), do: string_key_map(map)
  defp string_key_value(other), do: other

  defp normalize_status(nil), do: "unknown"
  defp normalize_status(s) when is_binary(s), do: String.downcase(s) |> String.slice(0, 50)

  defp parse_decimal(nil), do: Decimal.new(0)
  defp parse_decimal(s) when is_binary(s), do: parse_decimal(s, Decimal.new(0))
  defp parse_decimal(n) when is_number(n), do: Decimal.from_float(n * 1.0)
  defp parse_decimal(_), do: Decimal.new(0)

  defp parse_decimal(nil, default), do: default
  defp parse_decimal("", _), do: Decimal.new(0)
  defp parse_decimal(s, _) when is_binary(s) do
    case Decimal.parse(String.trim(s)) do
      {d, _} -> d
      :error -> Decimal.new(0)
    end
  end
  defp parse_decimal(n, _) when is_number(n), do: Decimal.from_float(n * 1.0)
  defp parse_decimal(_, default), do: default

  defp parse_int(nil, default), do: default
  defp parse_int("", default), do: default
  defp parse_int(n, _) when is_integer(n), do: n
  defp parse_int(s, default) when is_binary(s) do
    case Integer.parse(String.trim(s)) do
      {n, _} -> n
      :error -> default
    end
  end
  defp parse_int(_, default), do: default

  defp parse_datetime(nil), do: nil
  defp parse_datetime(s) when is_binary(s) do
    case DateTime.from_iso8601(s) do
      {:ok, dt, _} -> dt
      _ -> case NaiveDateTime.from_iso8601(s) do
             {:ok, ndt} -> DateTime.from_naive!(ndt, "Etc/UTC")
             _ -> nil
           end
    end
  end
  defp parse_datetime(_), do: nil

  defp to_external_id(nil), do: nil
  defp to_external_id(s) when is_binary(s), do: s
  defp to_external_id(n) when is_integer(n), do: to_string(n)
  defp to_external_id(other), do: to_string(other)
end
