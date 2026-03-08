defmodule SensorArray.Products.Product do
  @moduledoc "Product schema; team-scoped."
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "products" do
    field :external_id, :string
    field :source, :string
    field :name, :string
    field :sku, :string
    field :price, :decimal
    field :stock_quantity, :integer
    field :low_stock_threshold, :integer

    belongs_to :team, SensorArray.Accounts.Team

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
