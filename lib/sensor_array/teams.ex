defmodule SensorArray.Teams do
  @moduledoc """
  Context for teams. Stub API until Task 2 (schema + associations).
  """

  @doc "Returns all teams. Stub: always {:ok, []}."
  def list_teams, do: {:ok, []}

  @doc "Returns the team for the given id. Stub: always {:error, :not_found}."
  def get_team(_id), do: {:error, :not_found}
end
