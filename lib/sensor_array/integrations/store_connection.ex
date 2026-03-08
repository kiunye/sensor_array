defmodule SensorArray.Integrations.StoreConnection do
  @moduledoc """
  Store connection (Shopify or WooCommerce). API key stored encrypted via Cloak.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "store_connections" do
    field :platform, :string
    field :shop_url, :string
    field :api_key, :string, virtual: true, redact: true
    field :encrypted_api_key, SensorArray.Encrypted.Binary
    field :last_synced_at, :utc_datetime

    belongs_to :team, SensorArray.Accounts.Team

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(connection, attrs) do
    connection
    |> cast(attrs, [:platform, :shop_url, :api_key, :last_synced_at, :team_id])
    |> validate_required([:platform, :shop_url, :team_id])
    |> validate_inclusion(:platform, ~w(shopify woocommerce))
    |> put_encrypted_api_key()
    |> foreign_key_constraint(:team_id)
  end

  defp put_encrypted_api_key(changeset) do
    case get_change(changeset, :api_key) do
      nil -> changeset
      key -> put_change(changeset, :encrypted_api_key, key)
    end
  end
end
