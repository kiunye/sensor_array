defmodule SensorArray.Vault do
  @moduledoc """
  Cloak Vault for encrypting sensitive fields at rest (e.g. store API keys).
  Configure ciphers in config; use CLOAK_KEY in production.
  """
  use Cloak.Vault, otp_app: :sensor_array
end
