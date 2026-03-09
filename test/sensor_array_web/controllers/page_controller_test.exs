defmodule SensorArrayWeb.PageControllerTest do
  use SensorArrayWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)
    assert html =~ "Know your customers"
    assert html =~ "Grow your store"
    assert html =~ "Start free trial"
    assert html =~ "Features"
  end
end
