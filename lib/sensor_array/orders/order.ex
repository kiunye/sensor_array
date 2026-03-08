defmodule SensorArray.Orders.Order do
  @moduledoc "Order schema; team-scoped."
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "orders" do
    field :external_id, :string
    field :source, :string
    field :status, :string
    field :total, :decimal
    field :currency, :string
    field :ordered_at, :utc_datetime

    belongs_to :team, SensorArray.Accounts.Team
    belongs_to :customer, SensorArray.Customers.Customer
    has_many :order_items, SensorArray.Orders.OrderItem

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
