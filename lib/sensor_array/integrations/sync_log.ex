defmodule SensorArray.Integrations.SyncLog do
  @moduledoc "Log of a store sync run; team-scoped."
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "sync_logs" do
    field :status, :string
    field :records_synced, :integer
    field :error, :string
    field :completed_at, :utc_datetime

    belongs_to :team, SensorArray.Accounts.Team
    belongs_to :connection, SensorArray.Integrations.StoreConnection
  end
end
