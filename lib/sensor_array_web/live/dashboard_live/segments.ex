defmodule SensorArrayWeb.DashboardLive.Segments do
  @moduledoc "Customer segments: new, returning, at risk, champions."
  use SensorArrayWeb, :live_view

  alias SensorArray.Analytics.ETSStore

  @impl true
  def mount(_params, _session, socket) do
    team_id = socket.assigns.current_scope.current_team_id
    SensorArrayWeb.Endpoint.subscribe("team:#{team_id}")
    metrics = ETSStore.get_metrics(team_id)
    segments = Map.get(metrics, :segments, %{new: 0, returning: 0, at_risk: 0, champions: 0})

    {:ok,
     socket
     |> assign(:page_title, "Segments")
     |> assign(:team_id, team_id)
     |> assign(:segments, segments)}
  end

  @impl true
  def handle_info("metrics_updated", socket) do
    metrics = ETSStore.get_metrics(socket.assigns.team_id)
    segments = Map.get(metrics, :segments, %{new: 0, returning: 0, at_risk: 0, champions: 0})
    {:noreply, assign(socket, :segments, segments)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-8 motion-reduce:animate-none">
      <h1 class="text-2xl font-semibold text-base-content tracking-tight">Segments</h1>

      <section class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <.segment_card
          label="New"
          value={@segments.new}
          class="motion-safe:animate-fade-in"
        />
        <.segment_card
          label="Returning"
          value={@segments.returning}
          class="motion-safe:animate-fade-in motion-safe:[animation-delay:50ms]"
        />
        <.segment_card
          label="At risk"
          value={@segments.at_risk}
          class="motion-safe:animate-fade-in motion-safe:[animation-delay:100ms]"
        />
        <.segment_card
          label="Champions"
          value={@segments.champions}
          class="motion-safe:animate-fade-in motion-safe:[animation-delay:150ms]"
        />
      </section>

      <div class="card bg-base-200 border border-base-300">
        <div class="card-body">
          <h2 class="card-title text-base">Counts</h2>
          <ul class="space-y-3 text-sm">
            <li class="flex justify-between items-center">
              <span class="text-base-content/80">New</span>
              <span class="font-display-nums">{@segments.new}</span>
            </li>
            <li class="flex justify-between items-center">
              <span class="text-base-content/80">Returning</span>
              <span class="font-display-nums">{@segments.returning}</span>
            </li>
            <li class="flex justify-between items-center">
              <span class="text-base-content/80">At risk</span>
              <span class="font-display-nums">{@segments.at_risk}</span>
            </li>
            <li class="flex justify-between items-center">
              <span class="text-base-content/80">Champions</span>
              <span class="font-display-nums text-primary">{@segments.champions}</span>
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

  defp segment_card(assigns) do
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
