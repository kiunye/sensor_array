defmodule SensorArray.Accounts do
  @moduledoc """
  Context for users and team membership. Stub API until Task 2 (auth + schema).
  """

  @doc "Returns the team for the given id. Stub: always {:error, :not_found}."
  def get_team(_id), do: {:error, :not_found}

  @doc "Returns users for the given team_id. Stub: always {:ok, []}."
  def list_users_for_team(_team_id), do: {:ok, []}

  @doc "Returns the user for the given id. Stub: always {:error, :not_found}."
  def get_user(_id), do: {:error, :not_found}
end
