defmodule SensorArray.Analytics.TeamAggregatorTest do
  use SensorArray.DataCase

  alias SensorArray.Accounts
  alias SensorArray.Analytics.ETSStore
  alias SensorArray.Analytics.TeamAggregator
  alias SensorArray.Analytics.TeamAggregatorSupervisor
  alias SensorArray.Ingestion

  describe "rebuild/1" do
    test "populates ETS with aggregations from Postgres" do
      team = Accounts.get_or_create_default_team()
      team_id = team.id

      # Insert data
      Ingestion.ingest_csv(team_id, "products", [
        %{"id" => "p1", "name" => "Widget", "price" => "10", "sku" => "W1", "stock_quantity" => "2", "low_stock_threshold" => "5"}
      ])
      Ingestion.ingest_csv(team_id, "customers", [
        %{"id" => "c1", "email" => "a@example.com", "first_name" => "A", "last_name" => "B"}
      ])
      Ingestion.ingest_csv(team_id, "orders", [
        %{"id" => "o1", "total" => "99", "status" => "completed", "customer_email" => "a@example.com"}
      ])

      {:ok, _pid} = TeamAggregatorSupervisor.get_or_start_aggregator(team_id)
      assert :ok == TeamAggregator.rebuild(team_id)

      metrics = ETSStore.get_metrics(team_id)
      assert is_list(metrics[{:sales_trend, :daily}])
      assert is_list(metrics[{:top_products, :revenue}])
      assert is_list(metrics[:inventory_alerts])
      assert %{viewed: _, added_to_cart: _, checkout: _, purchased: _} = metrics[:funnel]
      assert %{new: _, returning: _, at_risk: _, champions: _} = metrics[:segments]
    end

    test "funnel purchased count reflects completed orders when no funnel_events" do
      team = Accounts.get_or_create_default_team()
      team_id = team.id
      Ingestion.ingest_csv(team_id, "orders", [
        %{"id" => "o1", "total" => "50", "status" => "completed"},
        %{"id" => "o2", "total" => "30", "status" => "pending"}
      ])

      {:ok, _pid} = TeamAggregatorSupervisor.get_or_start_aggregator(team_id)
      assert :ok == TeamAggregator.rebuild(team_id)

      funnel = ETSStore.get(team_id, :funnel)
      assert funnel.purchased == 1
    end
  end
end
