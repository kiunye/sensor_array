defmodule SensorArrayWeb.DashboardLive.Funnel do
  @moduledoc "Conversion funnel: viewed → added to cart → checkout → purchased."
  use SensorArrayWeb, :live_view

  alias SensorArray.Analytics.ETSStore

  @impl true
  def mount(_params, _session, socket) do
    team_id = socket.assigns.current_scope.current_team_id
    SensorArrayWeb.Endpoint.subscribe("team:#{team_id}")
    metrics = ETSStore.get_metrics(team_id)
    funnel = Map.get(metrics, :funnel, %{viewed: 0, added_to_cart: 0, checkout: 0, purchased: 0})

    {:ok,
     socket
     |> assign(:page_title, "Funnel")
     |> assign(:team_id, team_id)
     |> assign(:funnel, funnel)}
  end

  @impl true
  def handle_info("metrics_updated", socket) do
    metrics = ETSStore.get_metrics(socket.assigns.team_id)
    funnel = Map.get(metrics, :funnel, %{viewed: 0, added_to_cart: 0, checkout: 0, purchased: 0})
    {:noreply, assign(socket, :funnel, funnel)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-8 motion-reduce:animate-none">
      <h1 class="text-2xl font-semibold text-base-content tracking-tight">Funnel</h1>

      <section class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <.funnel_stat label="Viewed" value={@funnel.viewed} class="motion-safe:animate-fade-in" />
        <.funnel_stat
          label="Added to cart"
          value={@funnel.added_to_cart}
          class="motion-safe:animate-fade-in motion-safe:[animation-delay:50ms]"
        />
        <.funnel_stat
          label="Checkout"
          value={@funnel.checkout}
          class="motion-safe:animate-fade-in motion-safe:[animation-delay:100ms]"
        />
        <.funnel_stat
          label="Purchased"
          value={@funnel.purchased}
          class="motion-safe:animate-fade-in motion-safe:[animation-delay:150ms]"
        />
      </section>

      <div class="card bg-base-200 border border-base-300">
        <div class="card-body">
          <h2 class="card-title text-base">Stages</h2>
          <ul class="space-y-3 text-sm">
            <li class="flex justify-between items-center">
              <span class="text-base-content/80">Viewed</span>
              <span class="font-display-nums">{@funnel.viewed}</span>
            </li>
            <li class="flex justify-between items-center">
              <span class="text-base-content/80">Added to cart</span>
              <span class="font-display-nums">{@funnel.added_to_cart}</span>
            </li>
            <li class="flex justify-between items-center">
              <span class="text-base-content/80">Checkout</span>
              <span class="font-display-nums">{@funnel.checkout}</span>
            </li>
            <li class="flex justify-between items-center">
              <span class="text-base-content/80">Purchased</span>
              <span class="font-display-nums text-primary">{@funnel.purchased}</span>
            </li>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :integer, required: true
  attr :class, :string, default: nil

  defp funnel_stat(assigns) do
    ~H"""
    <div class={["card bg-base-200 border border-base-300", @class]}>
      <div class="card-body p-4">
        <p class="text-xs uppercase tracking-wider text-base-content/70">{@label}</p>
        <p class="font-display-nums text-2xl font-semibold">{@value}</p>
      </div>
    </div>
    """
  end
end
