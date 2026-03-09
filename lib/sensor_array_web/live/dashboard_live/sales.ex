defmodule SensorArrayWeb.DashboardLive.Sales do
  @moduledoc "Sales trend: daily, weekly, monthly."
  use SensorArrayWeb, :live_view

  alias SensorArray.Analytics.ETSStore

  @impl true
  def mount(_params, _session, socket) do
    team_id = socket.assigns.current_scope.current_team_id
    SensorArrayWeb.Endpoint.subscribe("team:#{team_id}")
    metrics = ETSStore.get_metrics(team_id)
    daily = Map.get(metrics, {:sales_trend, :daily}, [])
    weekly = Map.get(metrics, {:sales_trend, :weekly}, [])
    monthly = Map.get(metrics, {:sales_trend, :monthly}, [])

    {:ok,
     socket
     |> assign(:page_title, "Sales")
     |> assign(:team_id, team_id)
     |> assign(:daily, daily)
     |> assign(:weekly, weekly)
     |> assign(:monthly, monthly)}
  end

  @impl true
  def handle_info("metrics_updated", socket) do
    metrics = ETSStore.get_metrics(socket.assigns.team_id)
    {:noreply,
     socket
     |> assign(:daily, Map.get(metrics, {:sales_trend, :daily}, []))
     |> assign(:weekly, Map.get(metrics, {:sales_trend, :weekly}, []))
     |> assign(:monthly, Map.get(metrics, {:sales_trend, :monthly}, []))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-8 motion-reduce:animate-none">
      <h1 class="text-2xl font-semibold text-base-content tracking-tight">Sales</h1>

      <section class="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div class="card bg-base-200 border border-base-300 motion-safe:animate-fade-in">
          <div class="card-body">
            <h2 class="card-title text-base">Daily</h2>
            <p class="font-display-nums text-2xl">{length(@daily)}</p>
            <p class="text-sm text-base-content/70">data points</p>
          </div>
        </div>
        <div class="card bg-base-200 border border-base-300 motion-safe:animate-fade-in motion-safe:[animation-delay:50ms]">
          <div class="card-body">
            <h2 class="card-title text-base">Weekly</h2>
            <p class="font-display-nums text-2xl">{length(@weekly)}</p>
            <p class="text-sm text-base-content/70">data points</p>
          </div>
        </div>
        <div class="card bg-base-200 border border-base-300 motion-safe:animate-fade-in motion-safe:[animation-delay:100ms]">
          <div class="card-body">
            <h2 class="card-title text-base">Monthly</h2>
            <p class="font-display-nums text-2xl">{length(@monthly)}</p>
            <p class="text-sm text-base-content/70">data points</p>
          </div>
        </div>
      </section>

      <%= if @daily != [] or @weekly != [] or @monthly != [] do %>
        <div class="card bg-base-200 border border-base-300">
          <div class="card-body">
            <h2 class="card-title text-base">Trend data</h2>
            <p class="text-sm text-base-content/80">
              Raw trend entries are available. Chart visualization can be added later.
            </p>
          </div>
        </div>
      <% else %>
        <div class="card bg-base-200 border border-base-300">
          <div class="card-body">
            <p class="text-sm text-base-content/70">No sales trend data yet. Import orders to populate.</p>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
