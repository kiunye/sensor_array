defmodule SensorArrayWeb.ImportLive do
  @moduledoc "CSV import: format selector and file upload; parses and ingests via Ingestion context."
  use SensorArrayWeb, :live_view

  alias SensorArray.Ingestion
  alias SensorArray.Ingestion.CsvParser

  @impl true
  def mount(_params, _session, socket) do
    team_id = socket.assigns.current_scope.current_team_id
    formats = [{"Orders", "orders"}, {"Products", "products"}, {"Customers", "customers"}]
    socket =
      socket
      |> assign(:team_id, team_id)
      |> assign(:format, "products")
      |> assign(:formats, formats)
      |> assign(:import_result, nil)
      |> allow_upload(:csv,
        accept: ~w(.csv text/csv),
        max_entries: 1,
        max_file_size: 10_000_000
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6">
        <.header>
          Import data
          <:subtitle>Upload a CSV file (orders, products, or customers). First row must be headers.</:subtitle>
        </.header>

        <form id="import-form" phx-submit="import" phx-change="validate" class="space-y-4">
          <div>
            <label for="format" class="block text-sm font-medium text-zinc-800 dark:text-zinc-200">Format</label>
            <select
              id="format"
              name="format"
              phx-change="set_format"
              class="mt-1 block w-full rounded-md border border-zinc-300 dark:border-zinc-600 bg-white dark:bg-zinc-900 px-3 py-2 text-zinc-900 dark:text-zinc-100"
            >
              <%= for {label, value} <- @formats do %>
                <option value={value} selected={@format == value}><%= label %></option>
              <% end %>
            </select>
          </div>

          <div>
            <.live_file_input upload={@uploads.csv} class="block w-full text-sm" />
            <%= for entry <- @uploads.csv.entries do %>
              <p class="mt-1 text-sm text-zinc-600 dark:text-zinc-400">
                <%= entry.client_name %> (<%= entry.client_size %> bytes)
              </p>
            <% end %>
            <%= for err <- upload_errors(@uploads.csv) do %>
              <p class="mt-1 text-sm text-red-600"><%= error_to_string(err) %></p>
            <% end %>
          </div>

          <button
            type="submit"
            class="btn btn-primary"
            phx-disable-with="Importing..."
          >
            Import
          </button>
        </form>

        <%= if @import_result do %>
          <div class="rounded-lg bg-zinc-100 dark:bg-zinc-800 p-4 text-sm">
            <p class="font-medium text-zinc-800 dark:text-zinc-200">Result</p>
            <p class="mt-1 text-zinc-600 dark:text-zinc-400"><%= @import_result %></p>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("set_format", %{"format" => format}, socket) do
    {:noreply, assign(socket, :format, format)}
  end

  def handle_event("validate", _params, socket), do: {:noreply, socket}

  def handle_event("import", _params, socket) do
    team_id = socket.assigns.team_id
    format = socket.assigns.format

    result =
      consume_uploaded_entries(socket, :csv, fn %{path: path}, _entry ->
        content = File.read!(path)
        rows = CsvParser.parse_to_maps(content)
        case Ingestion.ingest_csv(team_id, format, rows) do
          {:ok, counts} ->
            format_result(format, counts)

          {:error, reason} ->
            raise "Ingestion failed: #{inspect(reason)}"
        end
      end)

    socket =
      case result do
        {[], []} ->
          put_flash(socket, :error, "Please select a CSV file.")

        {[msg], []} ->
          socket
          |> put_flash(:info, "Import completed.")
          |> assign(:import_result, msg)

        {[], [_ | _]} ->
          put_flash(socket, :error, "Import failed. Check file format and try again.")
      end

    {:noreply, socket}
  end

  defp format_result("orders", %{orders: n}), do: "Imported #{n} order(s)."
  defp format_result("products", %{products: n}), do: "Imported #{n} product(s)."
  defp format_result("customers", %{customers: n}), do: "Imported #{n} customer(s)."
  defp format_result(_, counts), do: "Imported: #{inspect(counts)}"

  defp error_to_string(:too_large), do: "File is too large."
  defp error_to_string(:not_accepted), do: "Only .csv files are accepted."
  defp error_to_string(:too_many_files), do: "Only one file at a time."
  defp error_to_string(err), do: "Upload error: #{inspect(err)}"
end
