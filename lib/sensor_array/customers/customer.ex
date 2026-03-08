defmodule SensorArray.Customers.Customer do
  @moduledoc "Customer schema; team-scoped."
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "customers" do
    field :external_id, :string
    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :total_spent, :decimal
    field :order_count, :integer
    field :last_ordered_at, :utc_datetime
    field :segment, :string

    belongs_to :team, SensorArray.Accounts.Team

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
