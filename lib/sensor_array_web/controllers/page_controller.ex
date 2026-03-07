defmodule SensorArrayWeb.PageController do
  use SensorArrayWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
