defmodule SensorArray.IntegrationsTest do
  use SensorArray.DataCase

  alias SensorArray.Integrations
  alias SensorArray.Accounts

  describe "list_connections/1" do
    test "returns empty list when team has no connections" do
      team = Accounts.get_or_create_default_team()
      assert {:ok, []} == Integrations.list_connections(team.id)
    end
  end

  describe "get_connection_for_team/2" do
    test "returns not_found for non-existent id" do
      team = Accounts.get_or_create_default_team()
      assert {:error, :not_found} == Integrations.get_connection_for_team(Ecto.UUID.generate(), team.id)
    end
  end
end
