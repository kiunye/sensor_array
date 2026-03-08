defmodule SensorArray.Encrypted.Binary do
  @moduledoc "Cloak.Ecto type for encrypting string/binary fields at rest."
  use Cloak.Ecto.Binary, vault: SensorArray.Vault
end
