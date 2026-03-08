import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Oban: use testing mode so jobs run inline in tests
config :sensor_array, Oban, testing: :inline

# Configure your database (TEST_DATABASE_URL, or DATABASE_URL, or POSTGRES_* from .env).
partition = System.get_env("MIX_TEST_PARTITION") || ""
test_url =
  System.get_env("TEST_DATABASE_URL") ||
    case System.get_env("DATABASE_URL") do
      nil ->
        # Build from POSTGRES_* (same as dev) when DATABASE_URL unset
        user = System.get_env("POSTGRES_USER") || "postgres"
        pass = System.get_env("POSTGRES_PASSWORD") || "postgres"
        host = System.get_env("POSTGRES_HOST") || "localhost"
        "ecto://#{user}:#{pass}@#{host}/sensor_array_test#{partition}"
      url ->
        url
        |> String.replace(~r"/[^/]+$", "/sensor_array_test#{partition}")
    end

config :sensor_array, SensorArray.Repo,
  url: test_url,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :sensor_array, SensorArrayWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "dawOK9ipzuN9mgm/3d69jgHiMPsJHGDb/ukYFdEHgJN35OUKE0ggEVDHic9Fj8wU",
  server: false

# In test we don't send emails
config :sensor_array, SensorArray.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
