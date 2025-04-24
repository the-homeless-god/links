import http from 'k6/http';
import { check, sleep } from 'k6';

// Конфигурация теста
export const options = {
  // Количество одновременных пользователей
  vus: 100,
  // Продолжительность теста
  duration: '30s',
  // Пороговые значения для успешного прохождения теста
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% запросов должны быть быстрее 500 мс
    http_req_failed: ['rate<0.01'],   // менее 1% запросов могут завершиться с ошибкой
  },
};

// Имитация тестовых данных
const testLinks = [];
for (let i = 0; i < 10; i++) {
  testLinks.push(`test-link-${i}`);
}

// Функция инициализации
export function setup() {
  // Для настоящего тестирования здесь можно использовать API для создания тестовых данных
  // в текущей реализации предполагаем, что тестовые ссылки уже созданы
  return { links: testLinks };
}

// Основная функция, которая будет выполняться в рамках нагрузочного тестирования
export default function(data) {
  // Выбираем случайную ссылку из списка
  const linkId = data.links[Math.floor(Math.random() * data.links.length)];
  
  // Выполняем запрос на получение ссылки (для тестирования API)
  const apiResponse = http.get(`http://localhost:4000/api/links/${linkId}`);
  
  // Проверяем результаты
  check(apiResponse, {
    'API запрос успешен': (r) => r.status === 200,
    'API вернул правильный JSON': (r) => r.json().id === linkId,
  });
  
  // Выполняем запрос на редирект ссылки (для тестирования redirect controller)
  const redirectResponse = http.get(`http://localhost:4000/r/${linkId}`, { redirects: 0 });
  
  // Проверяем результаты редиректа
  check(redirectResponse, {
    'Редирект возвращает код 302': (r) => r.status === 302,
    'Редирект содержит корректный заголовок Location': (r) => r.headers.Location !== undefined,
  });
  
  // Пауза между запросами для имитации реального поведения пользователя
  sleep(Math.random() * 3);
}

// Функция завершения, выполняется после окончания теста
export function teardown(data) {
  // В реальном тестировании здесь можно удалить тестовые данные
  // console.log('Нагрузочное тестирование завершено');
} 