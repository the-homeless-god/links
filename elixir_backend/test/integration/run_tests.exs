IO.puts("Запуск интеграционных тестов...")

Path.wildcard("test/integration/**/*_test.exs")
|> Enum.each(&Code.require_file/1)

exit_code =
  if ExUnit.run() == %{failures: 0, skipped: 0, total: _, excluded: 0} do
    IO.puts("✅ Все интеграционные тесты успешно пройдены!")
    0
  else
    IO.puts("❌ Некоторые интеграционные тесты провалены.")
    1
  end

System.halt(exit_code)
