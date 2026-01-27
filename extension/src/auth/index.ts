import type { UserInfo, KeycloakConfig } from '@/types';
import { setAuthState, getKeycloakConfig, setKeycloakConfig } from '@/services/storage';

// Загрузка сохраненной конфигурации Keycloak
async function loadKeycloakConfig(): Promise<void> {
  const config = await getKeycloakConfig();
  if (config) {
    const keycloakUrlInput = document.getElementById('keycloakUrl') as HTMLInputElement;
    const realmInput = document.getElementById('realm') as HTMLInputElement;
    const clientIdInput = document.getElementById('clientId') as HTMLInputElement;

    if (keycloakUrlInput) keycloakUrlInput.value = config.url || 'http://localhost:8080';
    if (realmInput) realmInput.value = config.realm || 'links-app';
    if (clientIdInput) clientIdInput.value = config.clientId || 'links-backend';
  }
}

// Сохранение конфигурации Keycloak
async function saveKeycloakConfig(): Promise<KeycloakConfig> {
  const keycloakUrlInput = document.getElementById('keycloakUrl') as HTMLInputElement;
  const realmInput = document.getElementById('realm') as HTMLInputElement;
  const clientIdInput = document.getElementById('clientId') as HTMLInputElement;

  if (!keycloakUrlInput || !realmInput || !clientIdInput) {
    throw new Error('Keycloak config inputs not found');
  }

  const config: KeycloakConfig = {
    url: keycloakUrlInput.value,
    realm: realmInput.value,
    clientId: clientIdInput.value,
  };

  await setKeycloakConfig(config);
  return config;
}

// Авторизация через Keycloak
async function loginWithKeycloak(username: string, password: string): Promise<void> {
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
      body: formData,
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Keycloak error: ${response.status} - ${errorText}`);
    }

    const tokenData = await response.json();
    const accessToken = tokenData.access_token as string;

    // Декодируем токен чтобы получить информацию о пользователе
    const userInfo = decodeJWT(accessToken);

    // Сохраняем токен и информацию о пользователе
    await setAuthState(accessToken, userInfo);

    // Перенаправляем на главную страницу
    window.location.href = 'popup.html';
  } catch (error) {
    console.error('Keycloak login error:', error);
    const errorMessage = error instanceof Error ? error.message : String(error);
    showError(`Ошибка авторизации: ${errorMessage}`);
  }
}

// Guest авторизация
async function loginAsGuest(): Promise<void> {
  try {
    const userInfo: UserInfo = {
      sub: 'guest',
      user_id: 'guest',
      preferred_username: 'guest',
    };

    await setAuthState('guest', userInfo);

    // Перенаправляем на главную страницу
    window.location.href = 'popup.html';
  } catch (error) {
    console.error('Guest login error:', error);
    const errorMessage = error instanceof Error ? error.message : String(error);
    showError(`Ошибка: ${errorMessage}`);
  }
}

// Декодирование JWT токена
function decodeJWT(token: string): UserInfo {
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
    return JSON.parse(decoded) as UserInfo;
  } catch (error) {
    console.error('JWT decode error:', error);
    return { sub: 'unknown', user_id: 'unknown' };
  }
}

// Показ ошибки
function showError(message: string): void {
  const errorDiv = document.getElementById('errorMessage');
  if (!errorDiv) return;

  errorDiv.textContent = message;
  errorDiv.classList.add('show');
  setTimeout(() => {
    errorDiv.classList.remove('show');
  }, 5000);
}

// Обработчики событий
document.addEventListener('DOMContentLoaded', () => {
  loadKeycloakConfig();

  const authForm = document.getElementById('authForm');
  const guestBtn = document.getElementById('guestBtn');

  if (authForm) {
    authForm.addEventListener('submit', async (e) => {
      e.preventDefault();

      const usernameInput = document.getElementById('username') as HTMLInputElement;
      const passwordInput = document.getElementById('password') as HTMLInputElement;

      if (!usernameInput || !passwordInput) {
        showError('Поля формы не найдены');
        return;
      }

      const username = usernameInput.value;
      const password = passwordInput.value;

      if (!username || !password) {
        showError('Пожалуйста, введите имя пользователя и пароль');
        return;
      }

      await loginWithKeycloak(username, password);
    });
  }

  if (guestBtn) {
    guestBtn.addEventListener('click', async () => {
      await loginAsGuest();
    });
  }
});
