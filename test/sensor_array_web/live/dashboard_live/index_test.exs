defmodule SensorArrayWeb.DashboardLive.IndexTest do
  use SensorArrayWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "dashboard overview when authenticated" do
    setup :register_and_log_in_user

    test "renders overview page with key metrics", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/dashboard")

      assert html =~ "Overview"
      assert html =~ "Funnel"
      assert html =~ "Segments"
      assert html =~ "Purchases"
      assert html =~ "Daily sales"
    end

    test "sidebar nav links are present", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/dashboard")

      assert html =~ ~p"/dashboard"
      assert html =~ ~p"/dashboard/sales"
      assert html =~ ~p"/dashboard/products"
      assert html =~ ~p"/dashboard/inventory"
      assert html =~ ~p"/dashboard/funnel"
      assert html =~ ~p"/dashboard/segments"
      assert html =~ ~p"/import"
    end
  end

  describe "dashboard when not authenticated" do
    test "redirects to log in", %{conn: conn} do
      assert {:error, {:redirect, %{to: to}}} = live(conn, ~p"/dashboard")
      assert to == ~p"/users/log-in"
    end
  end
end
