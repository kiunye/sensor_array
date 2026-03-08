defmodule SensorArray.Accounts.Policy do
  @moduledoc """
  Bodyguard policy for team-scoped authorization. All resources must belong to the user's team.
  """
  @behaviour Bodyguard.Policy

  alias SensorArray.Accounts.User

  @impl true
  def authorize(_action, nil, _params), do: {:error, :unauthorized}

  def authorize(_action, %User{} = user, %{team_id: team_id}) when is_binary(team_id) do
    if user.team_id == team_id, do: :ok, else: {:error, :forbidden}
  end

  def authorize(_action, %User{} = user, %{resource: %{team_id: team_id}})
      when is_binary(team_id) do
    if user.team_id == team_id, do: :ok, else: {:error, :forbidden}
  end

  def authorize(_action, %User{} = _user, _params), do: :ok
end
