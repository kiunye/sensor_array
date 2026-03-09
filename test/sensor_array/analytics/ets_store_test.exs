defmodule SensorArray.Analytics.ETSStoreTest do
  use SensorArray.DataCase

  alias SensorArray.Analytics.ETSStore
  alias SensorArray.Accounts

  describe "get_metrics/1 when table missing" do
    test "returns default metrics and does not raise" do
      team = Accounts.get_or_create_default_team()
      metrics = ETSStore.get_metrics(team.id)
      assert is_map(metrics)
      assert metrics[{:sales_trend, :daily}] == []
      assert metrics[{:sales_trend, :weekly}] == []
      assert metrics[:funnel] == %{viewed: 0, added_to_cart: 0, checkout: 0, purchased: 0}
      assert metrics[:segments] == %{new: 0, returning: 0, at_risk: 0, champions: 0}
    end
  end

  describe "get/2 when key missing" do
    test "returns default for known key" do
      team = Accounts.get_or_create_default_team()
      assert ETSStore.get(team.id, :funnel) == %{viewed: 0, added_to_cart: 0, checkout: 0, purchased: 0}
      assert ETSStore.get(team.id, {:sales_trend, :daily}) == []
      assert ETSStore.get(team.id, :segments) == %{new: 0, returning: 0, at_risk: 0, champions: 0}
    end
  end
end
