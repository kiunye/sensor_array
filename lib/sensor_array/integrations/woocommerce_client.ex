defmodule SensorArray.Integrations.WooCommerceClient do
  @moduledoc """
  Req-based client for WooCommerce REST API (v3). Fetches orders, products, and
  customers with page-based pagination, retries, and basic auth.
  """
  require Logger

  @per_page 100

  @doc "Fetch all orders, products, and customers for the given store connection. Returns {:ok, %{orders: [], products: [], customers: []}}."
  def fetch_all(conn) do
    base_url = base_url(conn)
    auth = basic_auth(conn)

    with {:ok, orders} <- fetch_paginated(base_url, auth, "orders"),
         {:ok, products} <- fetch_paginated(base_url, auth, "products"),
         {:ok, customers} <- fetch_paginated(base_url, auth, "customers") do
      {:ok, %{orders: orders, products: products, customers: customers}}
    end
  end

  defp base_url(%{shop_url: url}) do
    url = String.trim_trailing(url, "/")
    url = if String.starts_with?(url, "http"), do: url, else: "https://#{url}"
    "#{url}/wp-json/wc/v3"
  end

  defp basic_auth(conn) do
    # Store stores "consumer_key:consumer_secret"; WooCommerce uses Basic Auth with these.
    raw = conn.encrypted_api_key || ""
    case String.split(raw, ":", parts: 2) do
      [key, secret] -> {key, secret}
      _ -> {raw, ""}
    end
  end

  defp fetch_paginated(base_url, {user, pass}, resource) do
    collect_all(base_url, user, pass, resource, 1, [])
  end

  defp collect_all(base_url, user, pass, resource, page, acc) do
    url = "#{base_url}/#{resource}?per_page=#{@per_page}&page=#{page}"

    case Req.get(url,
           auth: {user, pass},
           retry: :transient,
           max_retries: 3
         ) do
      {:ok, %{status: 200, body: body}} when is_list(body) ->
        acc = acc ++ body
        if length(body) < @per_page, do: {:ok, acc}, else: collect_all(base_url, user, pass, resource, page + 1, acc)

      {:ok, resp} ->
        {:error, "WooCommerce API error: #{resp.status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
