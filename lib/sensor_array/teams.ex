defmodule SensorArray.Teams do
  @moduledoc """
  Context for teams. Delegates to Accounts for team data.
  """
  alias SensorArray.Accounts

  def list_teams, do: {:ok, Accounts.list_teams()}

  def get_team(id) do
    case Accounts.get_team(id) do
      nil -> {:error, :not_found}
      team -> {:ok, team}
    end
  end
end
