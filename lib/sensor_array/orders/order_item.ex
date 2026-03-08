defmodule SensorArray.Orders.OrderItem do
  @moduledoc "Order line item."
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "order_items" do
    field :quantity, :integer
    field :unit_price, :decimal
    field :total, :decimal

    belongs_to :order, SensorArray.Orders.Order
    belongs_to :product, SensorArray.Products.Product
  end
end
