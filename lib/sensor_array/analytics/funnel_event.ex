defmodule SensorArray.Analytics.FunnelEvent do
  @moduledoc "Funnel event (viewed, add_to_cart, checkout, purchased); team-scoped."
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "funnel_events" do
    field :session_id, :string
    field :event, :string
    field :occurred_at, :utc_datetime

    belongs_to :team, SensorArray.Accounts.Team
    belongs_to :product, SensorArray.Products.Product
  end
end
