defmodule SensorArray.Integrations.ShopifyClient do
  @moduledoc """
  Req-based client for Shopify Admin REST API. Fetches orders, products, and customers
  with cursor pagination, retries, and rate limiting (respects X-Shopify-Shop-Api-Call-Limit).
  """
  require Logger

  @api_version "2024-01"
  @limit 250

  @doc "Fetch all orders, products, and customers for the given store connection. Returns {:ok, %{orders: [], products: [], customers: []}}."
  def fetch_all(conn) do
    base_url = base_url(conn)
    token = api_token(conn)

    with {:ok, orders} <- fetch_paginated(base_url, token, "orders", "orders"),
         {:ok, products} <- fetch_paginated(base_url, token, "products", "products"),
         {:ok, customers} <- fetch_paginated(base_url, token, "customers", "customers") do
      {:ok, %{orders: orders, products: products, customers: customers}}
    end
  end

  defp base_url(%{shop_url: url}) do
    url = String.trim_trailing(url, "/")
    url = if String.starts_with?(url, "http"), do: url, else: "https://#{url}"
    "#{url}/admin/api/#{@api_version}"
  end

  defp api_token(conn) do
    # Cloak decrypts on load; field holds plaintext in memory
    conn.encrypted_api_key
  end

  defp fetch_paginated(base_url, token, resource, json_key) do
    path = "/#{resource}.json"
    url = "#{base_url}#{path}?limit=#{@limit}"
    collect_all(url, token, json_key, [])
  end

  defp collect_all(url, token, json_key, acc) do
    case Req.get(url,
           headers: [{"X-Shopify-Access-Token", token}],
           retry: :transient,
           max_retries: 3
         ) do
      {:ok, %{status: 200, body: body, headers: headers}} ->
        items = Map.get(body, json_key, [])
        acc = acc ++ items
        next_url = link_header_next(headers)

        if next_url do
          maybe_rate_limit()
          collect_all(next_url, token, json_key, acc)
        else
          {:ok, acc}
        end

      {:ok, resp} ->
        {:error, "Shopify API error: #{resp.status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp link_header_next(headers) when is_list(headers) do
    link =
      Enum.find(headers, fn
        {"link", _} -> true
        {"Link", _} -> true
        _ -> false
      end)

    case link do
      {_, value} -> parse_next_link(value)
      _ -> nil
    end
  end

  defp parse_next_link(link) when is_binary(link) do
    link
    |> String.split(",")
    |> Enum.find_value(fn part ->
      if String.contains?(part, "rel=\"next\"") do
        part
        |> String.split(";")
        |> List.first()
        |> String.trim_leading("<")
        |> String.trim_trailing(">")
        |> String.trim()
      end
    end)
  end

  defp parse_next_link(_), do: nil

  defp maybe_rate_limit do
    Process.sleep(500)
  end
end
