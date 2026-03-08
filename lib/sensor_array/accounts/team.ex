defmodule SensorArray.Accounts.Team do
  @moduledoc """
  A team scopes all analytics data. Users belong to one team (for now).
  """
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "teams" do
    field :name, :string
    has_many :users, SensorArray.Accounts.User
    has_many :store_connections, SensorArray.Integrations.StoreConnection

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
