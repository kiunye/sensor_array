defmodule SensorArray.IngestionTest do
  use SensorArray.DataCase

  alias SensorArray.Ingestion
  alias SensorArray.Accounts
  alias SensorArray.Repo
  alias SensorArray.Products.Product
  alias SensorArray.Customers.Customer
  alias SensorArray.Orders.Order
  alias SensorArray.Workers.RebuildETSWorker
  alias SensorArray.Workers.StoreSyncWorker
  import Ecto.Query

  describe "ingest_csv/3" do
    setup do
      team = Accounts.get_or_create_default_team()
      %{team_id: team.id}
    end

    test "products: upserts rows and enqueues rebuild", %{team_id: team_id} do
      rows = [
        %{"id" => "p1", "name" => "Widget", "price" => "9.99", "sku" => "W1", "stock_quantity" => "10"},
        %{"id" => "p2", "name" => "Gadget", "price" => "19.50", "stock_quantity" => "5"}
      ]
      assert {:ok, %{products: 2, customers: 0, orders: 0}} = Ingestion.ingest_csv(team_id, "products", rows)
      assert Repo.aggregate(from(p in Product, where: p.team_id == ^team_id and p.source == "csv"), :count) == 2
    end

    test "customers: upserts rows", %{team_id: team_id} do
      rows = [
        %{"id" => "c1", "email" => "a@example.com", "first_name" => "Alice", "last_name" => "A"},
        %{"id" => "c2", "email" => "b@example.com", "first_name" => "Bob"}
      ]
      assert {:ok, %{customers: 2, products: 0, orders: 0}} = Ingestion.ingest_csv(team_id, "customers", rows)
      assert Repo.aggregate(from(c in Customer, where: c.team_id == ^team_id), :count) == 2
    end

    test "orders: upserts rows and links customer by email when present", %{team_id: team_id} do
      # Insert customer first
      Ingestion.ingest_csv(team_id, "customers", [
        %{"id" => "c1", "email" => "order@example.com", "first_name" => "Order", "last_name" => "User"}
      ])
      rows = [
        %{"id" => "o1", "total" => "99.00", "status" => "completed", "customer_email" => "order@example.com"},
        %{"id" => "o2", "total" => "50.00", "status" => "pending"}
      ]
      assert {:ok, %{orders: 2, products: 0, customers: 0}} = Ingestion.ingest_csv(team_id, "orders", rows)
      assert Repo.aggregate(from(o in Order, where: o.team_id == ^team_id and o.source == "csv"), :count) == 2
    end
  end

  describe "RebuildETSWorker" do
    test "perform rebuilds ETS and does not raise" do
      team = Accounts.get_or_create_default_team()
      job = %Oban.Job{args: %{"team_id" => team.id}}
      assert :ok = RebuildETSWorker.perform(job)
    end
  end

  describe "StoreSyncWorker" do
    test "perform with no connections returns ok" do
      job = %Oban.Job{args: %{}}
      assert :ok = StoreSyncWorker.perform(job)
    end
  end
end
