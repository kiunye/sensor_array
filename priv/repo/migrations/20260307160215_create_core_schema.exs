defmodule SensorArray.Repo.Migrations.CreateCoreSchema do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    # Teams (must exist before users)
    create table(:teams, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    # Users (auth + team)
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :team_id, references(:teams, on_delete: :delete_all, type: :binary_id), null: false
      add :email, :citext, null: false
      add :hashed_password, :string
      add :confirmed_at, :utc_datetime
      add :role, :string, null: false, default: "member"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])

    # User session tokens (phx.gen.auth)
    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      add :authenticated_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])

    # Store connections
    create table(:store_connections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :team_id, references(:teams, on_delete: :delete_all, type: :binary_id), null: false
      add :platform, :string, null: false
      add :shop_url, :string, null: false
      add :encrypted_api_key, :binary, null: false
      add :last_synced_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    # Products
    create table(:products, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :team_id, references(:teams, on_delete: :delete_all, type: :binary_id), null: false
      add :external_id, :string
      add :source, :string, null: false
      add :name, :string, null: false
      add :sku, :string
      add :price, :decimal, precision: 10, scale: 2
      add :stock_quantity, :integer, default: 0
      add :low_stock_threshold, :integer, default: 10

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:products, [:team_id, :external_id, :source])
    create index(:products, [:team_id, :stock_quantity])

    # Customers
    create table(:customers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :team_id, references(:teams, on_delete: :delete_all, type: :binary_id), null: false
      add :external_id, :string
      add :email, :string
      add :first_name, :string
      add :last_name, :string
      add :total_spent, :decimal, precision: 10, scale: 2, default: 0
      add :order_count, :integer, default: 0
      add :last_ordered_at, :utc_datetime
      add :segment, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:customers, [:team_id, :external_id])
    create index(:customers, [:team_id, :segment])

    # Orders
    create table(:orders, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :team_id, references(:teams, on_delete: :delete_all, type: :binary_id), null: false
      add :customer_id, references(:customers, on_delete: :nilify_all, type: :binary_id)
      add :external_id, :string
      add :source, :string, null: false
      add :status, :string, null: false
      add :total, :decimal, precision: 10, scale: 2, null: false
      add :currency, :string, default: "USD"
      add :ordered_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:orders, [:team_id, :external_id, :source])
    create index(:orders, [:team_id, :ordered_at])
    create index(:orders, [:team_id, :status])

    # Order items
    create table(:order_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :order_id, references(:orders, on_delete: :delete_all, type: :binary_id), null: false
      add :product_id, references(:products, on_delete: :nilify_all, type: :binary_id)
      add :quantity, :integer, null: false
      add :unit_price, :decimal, precision: 10, scale: 2, null: false
      add :total, :decimal, precision: 10, scale: 2, null: false
    end

    create index(:order_items, [:order_id])

    # Funnel events
    create table(:funnel_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :team_id, references(:teams, on_delete: :delete_all, type: :binary_id), null: false
      add :session_id, :string
      add :event, :string, null: false
      add :product_id, references(:products, on_delete: :nilify_all, type: :binary_id)
      add :occurred_at, :utc_datetime, default: fragment("now()")
    end

    create index(:funnel_events, [:team_id, :event, :occurred_at])

    # Sync logs
    create table(:sync_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :team_id, references(:teams, on_delete: :delete_all, type: :binary_id), null: false
      add :connection_id, references(:store_connections, on_delete: :delete_all, type: :binary_id), null: false
      add :status, :string, null: false
      add :records_synced, :integer, default: 0
      add :error, :string
      add :completed_at, :utc_datetime, default: fragment("now()")
    end
  end
end
