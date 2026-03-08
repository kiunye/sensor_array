# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# Load .env into the environment when present (dev/test). Do not commit .env; use .env.example as a template.
env_path = Path.expand("../.env", __DIR__)
if File.exists?(env_path) do
  env_path
  |> File.stream!()
  |> Stream.map(&String.trim/1)
  |> Stream.reject(&(&1 == "" or String.starts_with?(&1, "#")))
  |> Enum.each(fn line ->
    case String.split(line, "=", parts: 2) do
      [key, value] ->
        value = value |> String.trim() |> String.trim_leading("\"") |> String.trim_trailing("\"")
        System.put_env(String.trim(key), value)
      _ ->
        :ok
    end
  end)
end

# General application configuration
import Config

config :sensor_array, :scopes,
  user: [
    default: true,
    module: SensorArray.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: SensorArray.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :sensor_array,
  ecto_repos: [SensorArray.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :sensor_array, SensorArrayWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: SensorArrayWeb.ErrorHTML, json: SensorArrayWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: SensorArray.PubSub,
  live_view: [signing_salt: "Q5/appw+"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :sensor_array, SensorArray.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  sensor_array: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  sensor_array: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Oban: repo and queue definitions (sync queue for store sync workers)
config :sensor_array, Oban,
  repo: SensorArray.Repo,
  queues: [default: 10, sync: 10],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 300},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 * * * *", SensorArray.Workers.StoreSyncWorker, queue: :sync}
     ]}
  ]

# Cloak: encryption for store API keys (Vault module defined in lib).
# Production: key is set in config/runtime.exs from CLOAK_KEY (required at runtime).
# Dev/test: fallback below when CLOAK_KEY is unset.
cloak_key =
  if config_env() == :prod do
    # Placeholder; overwritten in runtime.exs from CLOAK_KEY
    <<0::256>>
  else
    Base.decode64!(System.get_env("CLOAK_KEY") || Base.encode64(String.duplicate("A", 32)))
  end

config :cloak, SensorArray.Vault,
  json_library: Jason,
  ciphers: [
    default:
      {Cloak.Ciphers.AES.GCM,
       tag: "AES.GCM.V1",
       key: cloak_key}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
