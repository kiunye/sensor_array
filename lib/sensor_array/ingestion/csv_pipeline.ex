defmodule SensorArray.Ingestion.CsvPipeline do
  @moduledoc """
  Broadway pipeline for CSV row ingestion. No-op placeholder: uses
  DummyProducer (no messages). Task 3 will replace with real producer
  fed by LiveView uploads and add normalization stages.
  """
  use Broadway

  def start_link(_opts \\ []) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {Broadway.DummyProducer, []},
        concurrency: 1
      ],
      processors: [
        default: [concurrency: 1]
      ],
      batchers: [
        default: [batch_size: 10, concurrency: 1]
      ]
    )
  end

  @impl true
  def handle_message(_processor, message, _context) do
    message
  end

  @impl true
  def handle_batch(_batch_name, messages, _batch_info, _context) do
    # No-op: in Task 3 we will persist to Repo and trigger ETS rebuild
    messages
  end
end
