defmodule SensorArrayWeb.DashboardLive.Index do
  @moduledoc "Dashboard overview: key metrics at a glance."
  use SensorArrayWeb, :live_view

  alias SensorArray.Analytics.ETSStore

  @impl true
  def mount(_params, _session, socket) do
    team_id = socket.assigns.current_scope.current_team_id
    topic = "team:#{team_id}"
    SensorArrayWeb.Endpoint.subscribe(topic)

    metrics = ETSStore.get_metrics(team_id)
    funnel = Map.get(metrics, :funnel, %{viewed: 0, added_to_cart: 0, checkout: 0, purchased: 0})
    segments = Map.get(metrics, :segments, %{new: 0, returning: 0, at_risk: 0, champions: 0})
    sales_daily = Map.get(metrics, {:sales_trend, :daily}, []) |> length()
    top_products = Map.get(metrics, {:top_products, :revenue}, []) |> length()
    alerts = Map.get(metrics, :inventory_alerts, []) |> length()

    socket =
      socket
      |> assign(:page_title, "Overview")
      |> assign(:team_id, team_id)
      |> assign(:metrics, metrics)
      |> assign(:funnel, funnel)
      |> assign(:segments, segments)
      |> assign(:sales_daily_count, sales_daily)
      |> assign(:top_products_count, top_products)
      |> assign(:inventory_alerts_count, alerts)

    {:ok, socket}
  end

  @impl true
  def handle_info("metrics_updated", socket) do
    metrics = ETSStore.get_metrics(socket.assigns.team_id)
    funnel = Map.get(metrics, :funnel, %{viewed: 0, added_to_cart: 0, checkout: 0, purchased: 0})
    segments = Map.get(metrics, :segments, %{new: 0, returning: 0, at_risk: 0, champions: 0})
    sales_daily = Map.get(metrics, {:sales_trend, :daily}, []) |> length()
    top_products = Map.get(metrics, {:top_products, :revenue}, []) |> length()
    alerts = Map.get(metrics, :inventory_alerts, []) |> length()

    {:noreply,
     socket
     |> assign(:metrics, metrics)
     |> assign(:funnel, funnel)
     |> assign(:segments, segments)
     |> assign(:sales_daily_count, sales_daily)
     |> assign(:top_products_count, top_products)
     |> assign(:inventory_alerts_count, alerts)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-8 motion-reduce:animate-none">
      <h1 class="text-2xl font-semibold text-base-content tracking-tight">Overview</h1>

      <section class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4" aria-label="Key metrics">
        <.metric_card
          title="Purchases (funnel)"
          value={@funnel.purchased}
          class="motion-safe:animate-fade-in motion-safe:[animation-delay:0ms]"
        />
        <.metric_card
          title="Daily sales points"
          value={@sales_daily_count}
          class="motion-safe:animate-fade-in motion-safe:[animation-delay:50ms]"
        />
        <.metric_card
          title="Top products"
          value={@top_products_count}
          class="motion-safe:animate-fade-in motion-safe:[animation-delay:100ms]"
        />
        <.metric_card
          title="Inventory alerts"
          value={@inventory_alerts_count}
          class="motion-safe:animate-fade-in motion-safe:[animation-delay:150ms]"
        />
      </section>

      <section class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div class="card bg-base-200 border border-base-300 motion-safe:animate-fade-in motion-safe:[animation-delay:200ms]">
          <div class="card-body">
            <h2 class="card-title text-base">Funnel</h2>
            <ul class="space-y-2 text-sm">
              <li class="flex justify-between">
                <span class="text-base-content/80">Viewed</span>
                <span class="font-display-nums">{@funnel.viewed}</span>
              </li>
              <li class="flex justify-between">
                <span class="text-base-content/80">Added to cart</span>
                <span class="font-display-nums">{@funnel.added_to_cart}</span>
              </li>
              <li class="flex justify-between">
                <span class="text-base-content/80">Checkout</span>
                <span class="font-display-nums">{@funnel.checkout}</span>
              </li>
              <li class="flex justify-between">
                <span class="text-base-content/80">Purchased</span>
                <span class="font-display-nums text-primary">{@funnel.purchased}</span>
              </li>
            </ul>
            <.link navigate={~p"/dashboard/funnel"} class="link link-primary text-sm mt-2">
              View funnel →
            </.link>
          </div>
        </div>
        <div class="card bg-base-200 border border-base-300 motion-safe:animate-fade-in motion-safe:[animation-delay:250ms]">
          <div class="card-body">
            <h2 class="card-title text-base">Segments</h2>
            <ul class="space-y-2 text-sm">
              <li class="flex justify-between">
                <span class="text-base-content/80">New</span>
                <span class="font-display-nums">{@segments.new}</span>
              </li>
              <li class="flex justify-between">
                <span class="text-base-content/80">Returning</span>
                <span class="font-display-nums">{@segments.returning}</span>
              </li>
              <li class="flex justify-between">
                <span class="text-base-content/80">At risk</span>
                <span class="font-display-nums">{@segments.at_risk}</span>
              </li>
              <li class="flex justify-between">
                <span class="text-base-content/80">Champions</span>
                <span class="font-display-nums text-primary">{@segments.champions}</span>
              </li>
            </ul>
            <.link navigate={~p"/dashboard/segments"} class="link link-primary text-sm mt-2">
              View segments →
            </.link>
          </div>
        </div>
      </section>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :value, :any, required: true
  attr :class, :string, default: nil

  defp metric_card(assigns) do
    ~H"""
    <div class={["card bg-base-200 border border-base-300", @class]}>
      <div class="card-body p-4">
        <p class="text-xs uppercase tracking-wider text-base-content/70">{@title}</p>
        <p class="font-display-nums text-2xl font-semibold text-base-content">{@value}</p>
      </div>
    </div>
    """
  end
end
