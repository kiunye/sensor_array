defmodule SensorArrayWeb.DashboardLive.Inventory do
  @moduledoc "Inventory alerts."
  use SensorArrayWeb, :live_view

  alias SensorArray.Analytics.ETSStore

  @impl true
  def mount(_params, _session, socket) do
    team_id = socket.assigns.current_scope.current_team_id
    SensorArrayWeb.Endpoint.subscribe("team:#{team_id}")
    metrics = ETSStore.get_metrics(team_id)
    alerts = Map.get(metrics, :inventory_alerts, [])

    {:ok,
     socket
     |> assign(:page_title, "Inventory")
     |> assign(:team_id, team_id)
     |> assign(:alerts, alerts)}
  end

  @impl true
  def handle_info("metrics_updated", socket) do
    metrics = ETSStore.get_metrics(socket.assigns.team_id)
    {:noreply, assign(socket, :alerts, Map.get(metrics, :inventory_alerts, []))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-8 motion-reduce:animate-none">
      <h1 class="text-2xl font-semibold text-base-content tracking-tight">Inventory alerts</h1>

      <%= if @alerts == [] do %>
        <div class="card bg-base-200 border border-base-300">
          <div class="card-body">
            <p class="text-sm text-base-content/70">No inventory alerts.</p>
          </div>
        </div>
      <% else %>
        <ul class="space-y-2">
          <%= for alert <- @alerts do %>
            <li class="card bg-base-200 border border-base-300 motion-safe:animate-fade-in">
              <div class="card-body py-3">
                <.alert_line alert={alert} />
              </div>
            </li>
          <% end %>
        </ul>
      <% end %>
    </div>
    """
  end

  attr :alert, :map, required: true

  defp alert_line(assigns) do
    ~H"""
    <p class="text-sm text-base-content">
      <span class="font-display-nums"><%= @alert[:sku] || "—" %></span>
      — stock <span class="font-display-nums"><%= @alert[:stock] %></span>
      (threshold <span class="font-display-nums"><%= @alert[:threshold] %></span>)
    </p>
    """
  end
end
