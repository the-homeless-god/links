defmodule LinksApi.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller периодически собирает базовые метрики
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000},
      # Добавляем плагин для Prometheus
      {TelemetryMetricsPrometheus, [metrics: metrics()]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix метрики
      counter("phoenix.endpoint.start.system_time",
        description: "Количество запросов к серверу"
      ),
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond},
        tags: [:method, :request_path, :status],
        description: "Время обработки запроса по методу и пути"
      ),
      summary("phoenix.router_dispatch.stop.duration",
        unit: {:native, :millisecond},
        tags: [:route],
        description: "Время обработки запроса по маршруту"
      ),

      # LiveView метрики
      summary("phoenix.live_view.mount.stop.duration",
        unit: {:native, :millisecond},
        tags: [:view],
        description: "Время монтирования LiveView"
      ),
      summary("phoenix.live_view.handle_params.stop.duration",
        unit: {:native, :millisecond},
        tags: [:view],
        description: "Время обработки параметров в LiveView"
      ),
      summary("phoenix.live_view.handle_event.stop.duration",
        unit: {:native, :millisecond},
        tags: [:view, :event],
        description: "Время обработки событий в LiveView"
      ),

      # Метрики базы данных
      summary("links_api.repo.query.total_time",
        unit: {:native, :millisecond},
        tags: [:source, :command],
        description: "Общее время выполнения запросов к БД"
      ),
      summary("links_api.repo.query.decode_time",
        unit: {:native, :millisecond},
        tags: [:source, :command],
        description: "Время декодирования запроса"
      ),
      summary("links_api.repo.query.query_time",
        unit: {:native, :millisecond},
        tags: [:source, :command],
        description: "Время выполнения запроса"
      ),

      # Кастомные метрики приложения
      counter("links_api.links.created.count",
        description: "Количество созданных ссылок"
      ),
      counter("links_api.links.updated.count",
        description: "Количество обновленных ссылок"
      ),
      counter("links_api.links.deleted.count",
        description: "Количество удаленных ссылок"
      ),
      counter("links_api.links.redirect.count",
        tags: [:group_id],
        description: "Количество переходов по ссылкам"
      ),

      # VM метрики
      summary("vm.memory.total", unit: {:byte, :kilobyte}, description: "Общая память VM"),
      summary("vm.total_run_queue_lengths.total", description: "Общая длина очереди VM"),
      summary("vm.total_run_queue_lengths.cpu", description: "Длина очереди CPU"),
      summary("vm.total_run_queue_lengths.io", description: "Длина очереди IO")
    ]
  end

  defp periodic_measurements do
    [
      # Функция для периодического сбора метрик VM
      {:process_info, LinksApi.SystemMetrics, :vm_metrics, []}
    ]
  end
end
