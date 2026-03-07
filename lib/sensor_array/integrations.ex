defmodule SensorArray.Integrations do
  @moduledoc """
  Context for store connections (Shopify, WooCommerce). Stub API until Task 2.
  """

  @doc "Returns store connections for the given team_id. Stub: always {:ok, []}."
  def list_connections(_team_id), do: {:ok, []}

  @doc "Returns the connection for the given id. Stub: always {:error, :not_found}."
  def get_connection(_id), do: {:error, :not_found}
end
