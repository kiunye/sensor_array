defmodule SensorArray.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias SensorArray.Analytics.ETSStore
  alias SensorArray.Ingestion.CsvPipeline
  alias SensorArray.Repo
  alias SensorArrayWeb.Endpoint
  alias SensorArrayWeb.Telemetry

  @impl true
  def start(_type, _args) do
    children = [
      Telemetry,
      Repo,
      {DNSCluster, query: Application.get_env(:sensor_array, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SensorArray.PubSub},
      {Oban, Application.get_env(:sensor_array, Oban)},
      ETSStore,
      CsvPipeline,
      # Start to serve requests, typically the last entry
      Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SensorArray.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end
end
