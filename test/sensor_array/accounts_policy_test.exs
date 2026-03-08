defmodule SensorArray.Accounts.PolicyTest do
  use SensorArray.DataCase

  alias SensorArray.Accounts.Policy
  import SensorArray.AccountsFixtures

  describe "authorize/3 tenant boundary" do
    test "returns :ok when user team_id matches params team_id" do
      user = user_fixture()
      assert :ok == Bodyguard.permit(Policy, :show, user, team_id: user.team_id)
    end

    test "returns error when user team_id does not match params team_id" do
      user = user_fixture()
      other_team_id = Ecto.UUID.generate()
      assert {:error, :forbidden} == Bodyguard.permit(Policy, :show, user, team_id: other_team_id)
    end

    test "returns error when user is nil" do
      assert {:error, :unauthorized} == Bodyguard.permit(Policy, :show, nil, team_id: Ecto.UUID.generate())
    end

    test "returns :ok when params has resource with matching team_id" do
      user = user_fixture()
      resource = %{team_id: user.team_id}
      assert :ok == Bodyguard.permit(Policy, :show, user, resource: resource)
    end
  end
end
