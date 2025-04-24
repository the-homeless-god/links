defmodule LinksApi.SystemMetrics do
  @moduledoc """
  Модуль для сбора системных метрик.
  """
  require Logger

  # Функция для сбора метрик VM
  def vm_metrics() do
    :telemetry.execute([:links_api, :vm], %{
      memory: :erlang.memory(),
      process_count: :erlang.system_info(:process_count),
      io: get_io_stats()
    }, %{})
  end

  # Получение статистики IO
  defp get_io_stats() do
    {{:input, input}, {:output, output}} = :erlang.statistics(:io)
    %{input: input, output: output}
  end

  # Функция для логирования, что событие произошло
  def log_event(event_name, metadata \\ %{}) do
    Logger.info("Event occurred", event: event_name, metadata: metadata)
  end

  # Функция для измерения времени выполнения функции
  def measure_time(module, function, args) do
    {time, result} = :timer.tc(module, function, args)

    # Логируем время выполнения
    Logger.debug("Function execution time",
      module: module,
      function: function,
      execution_time_ms: time / 1000
    )

    # Возвращаем результат
    result
  end
end
