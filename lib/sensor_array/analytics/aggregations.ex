defmodule SensorArray.Analytics.Aggregations do
  @moduledoc """
  Computes team-scoped aggregations from Postgres for ETS.
  Used by TeamAggregator; returns data in the shape expected by ETS keys.
  """
  import Ecto.Query
  alias SensorArray.Repo
  alias SensorArray.Orders.Order
  alias SensorArray.Orders.OrderItem
  alias SensorArray.Products.Product
  alias SensorArray.Customers.Customer
  alias SensorArray.Analytics.FunnelEvent

  @doc "Sales trend by day: [%{date: date, revenue: decimal, orders: count}]"
  def sales_trend_daily(team_id) do
    from(o in Order,
      where: o.team_id == ^team_id and not is_nil(o.ordered_at) and o.status in ["completed", "paid", "fulfilled"],
      group_by: fragment("date_trunc('day', ?)", o.ordered_at),
      select: %{
        date: fragment("date_trunc('day', ?)", o.ordered_at),
        revenue: sum(o.total),
        orders: count(o.id)
      },
      order_by: fragment("date_trunc('day', ?)", o.ordered_at)
    )
    |> Repo.all()
    |> Enum.map(&map_date_revenue_orders/1)
  end

  @doc "Sales trend by week."
  def sales_trend_weekly(team_id) do
    from(o in Order,
      where: o.team_id == ^team_id and not is_nil(o.ordered_at) and o.status in ["completed", "paid", "fulfilled"],
      group_by: fragment("date_trunc('week', ?)", o.ordered_at),
      select: %{
        week: fragment("date_trunc('week', ?)", o.ordered_at),
        revenue: sum(o.total),
        orders: count(o.id)
      },
      order_by: fragment("date_trunc('week', ?)", o.ordered_at)
    )
    |> Repo.all()
    |> Enum.map(fn row ->
      %{week: format_week(row.week), revenue: to_decimal(row.revenue), orders: row.orders}
    end)
  end

  @doc "Sales trend by month."
  def sales_trend_monthly(team_id) do
    from(o in Order,
      where: o.team_id == ^team_id and not is_nil(o.ordered_at) and o.status in ["completed", "paid", "fulfilled"],
      group_by: fragment("date_trunc('month', ?)", o.ordered_at),
      select: %{
        month: fragment("date_trunc('month', ?)", o.ordered_at),
        revenue: sum(o.total),
        orders: count(o.id)
      },
      order_by: fragment("date_trunc('month', ?)", o.ordered_at)
    )
    |> Repo.all()
    |> Enum.map(fn row ->
      %{month: format_month(row.month), revenue: to_decimal(row.revenue), orders: row.orders}
    end)
  end

  @doc "Top products by revenue: [%{id, name, revenue, units}]"
  def top_products_revenue(team_id) do
    from(oi in OrderItem,
      join: o in Order, on: oi.order_id == o.id,
      join: p in Product, on: oi.product_id == p.id,
      where: o.team_id == ^team_id,
      group_by: [p.id, p.name],
      select: %{
        id: p.id,
        name: p.name,
        revenue: sum(oi.total),
        units: sum(oi.quantity)
      },
      order_by: [desc: sum(oi.total)],
      limit: 50
    )
    |> Repo.all()
    |> Enum.map(fn row ->
      %{id: row.id, name: row.name || "Unknown", revenue: to_decimal(row.revenue), units: row.units || 0}
    end)
  end

  @doc "Inventory alerts: [%{product_id, sku, stock, threshold}]"
  def inventory_alerts(team_id) do
    from(p in Product,
      where: p.team_id == ^team_id and not is_nil(p.low_stock_threshold) and p.stock_quantity <= p.low_stock_threshold,
      select: %{product_id: p.id, sku: p.sku, stock: p.stock_quantity, threshold: p.low_stock_threshold}
    )
    |> Repo.all()
  end

  @doc "Funnel: from funnel_events when present; else approximate purchased from orders. Returns %{viewed, added_to_cart, checkout, purchased}."
  def funnel(team_id) do
    event_counts =
      from(f in FunnelEvent,
        where: f.team_id == ^team_id,
        group_by: f.event,
        select: {f.event, count(f.id)}
      )
      |> Repo.all()
      |> Map.new(fn {event, count} -> {normalize_funnel_event(event), count} end)

    if map_size(event_counts) > 0 do
      %{
        viewed: event_counts["viewed"] || 0,
        added_to_cart: event_counts["added_to_cart"] || event_counts["add_to_cart"] || 0,
        checkout: event_counts["checkout"] || 0,
        purchased: event_counts["purchased"] || 0
      }
    else
      # Approximate from orders: purchased = completed orders
      purchased =
        from(o in Order,
          where: o.team_id == ^team_id and o.status in ["completed", "paid", "fulfilled"],
          select: count(o.id)
        )
        |> Repo.one() || 0

      %{viewed: 0, added_to_cart: 0, checkout: 0, purchased: purchased}
    end
  end

  @doc "Customer segments (RFM): %{new, returning, at_risk, champions}. Configurable via :rfm config."
  def segments(team_id) do
    cfg = Application.get_env(:sensor_array, :rfm, [])
    recency_days = Keyword.get(cfg, :recency_days, [30, 90, 180])
    frequency_breaks = Keyword.get(cfg, :frequency_breaks, [1, 2, 5])
    monetary_breaks = Keyword.get(cfg, :monetary_breaks, [0, 50, 200, 500])

    customers =
      from(c in Customer, where: c.team_id == ^team_id, select: c)
      |> Repo.all()

    now = DateTime.utc_now()
    new_count = 0
    returning_count = 0
    at_risk_count = 0
    champions_count = 0

    {new_count, returning_count, at_risk_count, champions_count} =
      Enum.reduce(customers, {new_count, returning_count, at_risk_count, champions_count}, fn c, acc ->
        recency_days_val = days_since(c.last_ordered_at, now)
        freq = c.order_count || 0
        monetary = Decimal.to_float(c.total_spent || 0)

        segment = segment_from_rfm(recency_days_val, freq, monetary, recency_days, frequency_breaks, monetary_breaks)
        update_segment_counts(segment, acc)
      end)

    %{new: new_count, returning: returning_count, at_risk: at_risk_count, champions: champions_count}
  end

  defp map_date_revenue_orders(row) do
    %{
      date: format_date(row.date),
      revenue: to_decimal(row.revenue),
      orders: row.orders
    }
  end

  defp format_date(nil), do: nil
  defp format_date(%DateTime{} = dt), do: DateTime.to_date(dt) |> to_string()
  defp format_date(%NaiveDateTime{} = dt), do: NaiveDateTime.to_date(dt) |> to_string()
  defp format_date(dt), do: to_string(dt)

  defp format_week(nil), do: nil
  defp format_week(dt) when is_struct(dt), do: to_string(dt)
  defp format_week(dt), do: to_string(dt)

  defp format_month(nil), do: nil
  defp format_month(dt) when is_struct(dt), do: to_string(dt)
  defp format_month(dt), do: to_string(dt)

  defp to_decimal(nil), do: Decimal.new(0)
  defp to_decimal(%Decimal{} = d), do: d
  defp to_decimal(n) when is_number(n), do: Decimal.from_float(n * 1.0)

  defp normalize_funnel_event(s) when is_binary(s), do: String.downcase(s) |> String.replace(" ", "_")
  defp normalize_funnel_event(_), do: "unknown"

  defp days_since(nil, _now), do: nil
  defp days_since(%NaiveDateTime{} = dt, now) do
    dt = DateTime.from_naive!(dt, "Etc/UTC")
    DateTime.diff(now, dt, :day)
  end
  defp days_since(%DateTime{} = dt, now), do: DateTime.diff(now, dt, :day)
  defp days_since(_, _), do: nil

  defp segment_from_rfm(recency_days, freq, monetary, rd, fb, mb) do
    # RFM with configurable breaks: new (1 order, recent), returning (2+, recent), at_risk (no order 90+ days), champions (high F+M, recent)
    r30 = recency_days != nil and recency_days <= (List.first(rd) || 30)
    r90 = recency_days != nil and recency_days <= (Enum.at(rd, 1) || 90)
    high_m = monetary >= (List.last(mb) || 200)
    high_f = freq >= (List.last(fb) || 5)

    cond do
      freq == 1 and r30 -> :new
      high_f and r30 and high_m -> :champions
      freq >= 2 and r90 -> :returning
      recency_days == nil or recency_days > (Enum.at(rd, 1) || 90) -> :at_risk
      true -> :returning
    end
  end

  defp update_segment_counts(:new, {n, r, a, c}), do: {n + 1, r, a, c}
  defp update_segment_counts(:returning, {n, r, a, c}), do: {n, r + 1, a, c}
  defp update_segment_counts(:at_risk, {n, r, a, c}), do: {n, r, a + 1, c}
  defp update_segment_counts(:champions, {n, r, a, c}), do: {n, r, a, c + 1}
end
