IO.puts("Запуск нагрузочных тестов...")

# Проверяем, установлен ли K6
k6_installed =
  case System.cmd("which", ["k6"], stderr_to_stdout: true) do
    {_, 0} -> true
    _ -> false
  end

if k6_installed do
  IO.puts("🔥 Запуск нагрузочных тестов с помощью K6...")

  # Запускаем нагрузочные тесты
  {output, exit_code} = System.cmd("k6", ["run", "test/load/load_test.js"], stderr_to_stdout: true)

  # Выводим результаты
  IO.puts(output)

  if exit_code == 0 do
    IO.puts("✅ Нагрузочные тесты успешно пройдены!")
  else
    IO.puts("❌ Нагрузочные тесты провалены.")
  end

  System.halt(exit_code)
else
  IO.puts("⚠️  K6 не установлен. Нагрузочные тесты пропущены.")
  IO.puts("   Для установки K6:")
  IO.puts("   - macOS: brew install k6")
  IO.puts("   - Linux: sudo apt-get install k6")
  IO.puts("   - Windows: choco install k6")
  IO.puts("   Или см. https://k6.io/docs/getting-started/installation/")

  # Пропускаем тест, но не считаем это ошибкой
  System.halt(0)
end
