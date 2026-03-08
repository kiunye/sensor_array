defmodule SensorArray.Ingestion.Upsert do
  @moduledoc """
  Idempotent bulk upsert of normalized attrs into products, customers, and orders.
  Uses Repo.insert_all with on_conflict to replace by (team_id, external_id, source).
  """
  alias SensorArray.Repo
  alias SensorArray.Products.Product
  alias SensorArray.Customers.Customer
  alias SensorArray.Orders.Order
  import Ecto.Query

  @product_conflict [:team_id, :external_id, :source]
  @customer_conflict [:team_id, :external_id]
  @order_conflict [:team_id, :external_id, :source]

  @doc "Upsert product attrs (list of maps). Returns count of rows affected."
  def products(team_id, attrs_list, source) when is_list(attrs_list) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    rows =
      Enum.map(attrs_list, fn attrs ->
        Map.merge(attrs, %{
          team_id: team_id,
          source: source,
          inserted_at: now
        })
        |> Map.take([
          :team_id, :external_id, :source, :name, :sku, :price,
          :stock_quantity, :low_stock_threshold, :inserted_at
        ])
      end)
    {count, _} = Repo.insert_all(
      Product,
      rows,
      on_conflict: {:replace_all_except, @product_conflict},
      conflict_target: @product_conflict
    )
    count
  end

  @doc "Upsert customer attrs. Returns count."
  def customers(team_id, attrs_list) when is_list(attrs_list) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    rows =
      Enum.map(attrs_list, fn attrs ->
        Map.merge(attrs, %{team_id: team_id, inserted_at: now})
        |> Map.take([
          :team_id, :external_id, :email, :first_name, :last_name,
          :total_spent, :order_count, :last_ordered_at, :segment, :inserted_at
        ])
      end)
    {count, _} = Repo.insert_all(
      Customer,
      rows,
      on_conflict: {:replace_all_except, @customer_conflict},
      conflict_target: @customer_conflict
    )
    count
  end

  @doc "Upsert order attrs (list of maps with optional customer_id). Extra keys (e.g. customer_email) are ignored."
  def orders(team_id, attrs_list, source) when is_list(attrs_list) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    keys = [:team_id, :external_id, :source, :customer_id, :status, :total, :currency, :ordered_at, :inserted_at]
    rows =
      Enum.map(attrs_list, fn attrs ->
        Map.merge(attrs, %{team_id: team_id, source: source, inserted_at: now})
        |> Map.take(keys)
      end)
    {count, _} = Repo.insert_all(
      Order,
      rows,
      on_conflict: {:replace_all_except, @order_conflict},
      conflict_target: @order_conflict
    )
    count
  end

  @doc "Look up customer id by team_id and external_id."
  def get_customer_id_by_external(team_id, external_id) when is_binary(external_id) do
    from(c in Customer, where: c.team_id == ^team_id and c.external_id == ^external_id, select: c.id)
    |> Repo.one()
  end

  @doc "Look up customer id by team_id and email."
  def get_customer_id_by_email(team_id, email) when is_binary(email) do
    from(c in Customer, where: c.team_id == ^team_id and c.email == ^email, select: c.id)
    |> Repo.one()
  end
end
