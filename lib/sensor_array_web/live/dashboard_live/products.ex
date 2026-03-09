defmodule SensorArrayWeb.DashboardLive.Products do
  @moduledoc "Top products by revenue."
  use SensorArrayWeb, :live_view

  alias SensorArray.Analytics.ETSStore

  @impl true
  def mount(_params, _session, socket) do
    team_id = socket.assigns.current_scope.current_team_id
    SensorArrayWeb.Endpoint.subscribe("team:#{team_id}")
    metrics = ETSStore.get_metrics(team_id)
    products = Map.get(metrics, {:top_products, :revenue}, [])

    {:ok,
     socket
     |> assign(:page_title, "Products")
     |> assign(:team_id, team_id)
     |> assign(:products, products)}
  end

  @impl true
  def handle_info("metrics_updated", socket) do
    metrics = ETSStore.get_metrics(socket.assigns.team_id)
    products = Map.get(metrics, {:top_products, :revenue}, [])
    {:noreply, assign(socket, :products, products)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-8 motion-reduce:animate-none">
      <h1 class="text-2xl font-semibold text-base-content tracking-tight">Top products (revenue)</h1>

      <%= if @products == [] do %>
        <div class="card bg-base-200 border border-base-300">
          <div class="card-body">
            <p class="text-sm text-base-content/70">No product data yet. Import orders and products to populate.</p>
          </div>
        </div>
      <% else %>
        <div class="card bg-base-200 border border-base-300 overflow-hidden motion-safe:animate-fade-in">
          <div class="overflow-x-auto">
            <table class="table table-zebra">
              <thead>
                <tr>
                  <th>Product</th>
                  <th class="text-right font-display-nums">Revenue</th>
                </tr>
              </thead>
              <tbody>
                <%= for product <- @products do %>
                  <tr>
                    <td><%= product[:name] || "Unknown" %></td>
                    <td class="text-right font-display-nums"><%= format_revenue(product[:revenue]) %></td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp format_revenue(%Decimal{} = d), do: "$#{Decimal.to_string(d, :normal)}"
  defp format_revenue(n) when is_number(n), do: "$#{:erlang.float_to_binary(n / 1, decimals: 2)}"
  defp format_revenue(_), do: "—"
end
