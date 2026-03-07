defmodule SensorArray.Repo do
  use Ecto.Repo,
    otp_app: :sensor_array,
    adapter: Ecto.Adapters.Postgres
end
