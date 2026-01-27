// Константы
const API_URL = 'http://localhost:4000';
const KEYCLOAK_CONFIG_KEY = 'keycloak_config';
const AUTH_TOKEN_KEY = 'auth_token';
const USER_INFO_KEY = 'user_info';

// Загрузка сохраненной конфигурации Keycloak
async function loadKeycloakConfig() {
  const result = await chrome.storage.local.get(KEYCLOAK_CONFIG_KEY);
  if (result[KEYCLOAK_CONFIG_KEY]) {
    const config = result[KEYCLOAK_CONFIG_KEY];
    document.getElementById('keycloakUrl').value = config.url || 'http://localhost:8080';
    document.getElementById('realm').value = config.realm || 'links-app';
    document.getElementById('clientId').value = config.clientId || 'links-backend';
  }
}

// Сохранение конфигурации Keycloak
async function saveKeycloakConfig() {
  const config = {
    url: document.getElementById('keycloakUrl').value,
    realm: document.getElementById('realm').value,
    clientId: document.getElementById('clientId').value
  };
  await chrome.storage.local.set({ [KEYCLOAK_CONFIG_KEY]: config });
  return config;
}

// Авторизация через Keycloak
async function loginWithKeycloak(username, password) {
  try {
    const config = await saveKeycloakConfig();
    
    const tokenUrl = `${config.url}/auth/realms/${config.realm}/protocol/openid-connect/token`;
    
    const formData = new URLSearchParams();
    formData.append('grant_type', 'password');
    formData.append('client_id', config.clientId);
    formData.append('username', username);
    formData.append('password', password);

    const response = await fetch(tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: formData
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Keycloak error: ${response.status} - ${errorText}`);
    }

    const tokenData = await response.json();
    const accessToken = tokenData.access_token;

    // Декодируем токен чтобы получить информацию о пользователе
    const userInfo = decodeJWT(accessToken);
    
    // Сохраняем токен и информацию о пользователе
    await chrome.storage.local.set({
      [AUTH_TOKEN_KEY]: accessToken,
      [USER_INFO_KEY]: userInfo
    });

    // Перенаправляем на главную страницу
    window.location.href = 'popup.html';
  } catch (error) {
    console.error('Keycloak login error:', error);
    showError(`Ошибка авторизации: ${error.message}`);
  }
}

// Guest авторизация
async function loginAsGuest() {
  try {
    // Сохраняем guest токен
    await chrome.storage.local.set({
      [AUTH_TOKEN_KEY]: 'guest',
      [USER_INFO_KEY]: {
        sub: 'guest',
        user_id: 'guest',
        preferred_username: 'guest'
      }
    });

    // Перенаправляем на главную страницу
    window.location.href = 'popup.html';
  } catch (error) {
    console.error('Guest login error:', error);
    showError(`Ошибка: ${error.message}`);
  }
}

// Декодирование JWT токена
function decodeJWT(token) {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) {
      throw new Error('Invalid JWT token');
    }

    // Декодируем payload (вторая часть)
    const payload = parts[1];
    // Добавляем padding если нужно
    const padding = (4 - (payload.length % 4)) % 4;
    const paddedPayload = payload + '='.repeat(padding);
    
    // Заменяем URL-safe символы
    const base64 = paddedPayload.replace(/-/g, '+').replace(/_/g, '/');
    
    // Декодируем
    const decoded = atob(base64);
    return JSON.parse(decoded);
  } catch (error) {
    console.error('JWT decode error:', error);
    return { sub: 'unknown', user_id: 'unknown' };
  }
}

// Показ ошибки
function showError(message) {
  const errorDiv = document.getElementById('errorMessage');
  errorDiv.textContent = message;
  errorDiv.classList.add('show');
  setTimeout(() => {
    errorDiv.classList.remove('show');
  }, 5000);
}

// Обработчики событий
document.addEventListener('DOMContentLoaded', () => {
  loadKeycloakConfig();

  // Форма авторизации
  document.getElementById('authForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;

    if (!username || !password) {
      showError('Пожалуйста, введите имя пользователя и пароль');
      return;
    }

    await loginWithKeycloak(username, password);
  });

  // Кнопка Guest
  document.getElementById('guestBtn').addEventListener('click', async () => {
    await loginAsGuest();
  });
});
