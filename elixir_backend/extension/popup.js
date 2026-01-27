// API конфигурация
let API_URL = 'http://localhost:4000';

// Константы для авторизации
const AUTH_TOKEN_KEY = 'auth_token';
const USER_INFO_KEY = 'user_info';

// Состояние приложения
let currentLinks = [];
let currentFilter = 'all';
let editingLinkId = null;
let actionButtonsSetup = false;
let authToken = null;
let userInfo = null;

// Инициализация
document.addEventListener('DOMContentLoaded', async () => {
  // Проверяем авторизацию
  const authResult = await checkAuth();
  if (!authResult) {
    // Если не авторизован, перенаправляем на страницу авторизации
    window.location.href = 'auth.html';
    return;
  }
  
  await loadSettings();
  await loadLinks();
  setupEventListeners();
  await fillCurrentPageUrl();
  
  // Настраиваем делегирование событий для кнопок действий
  setupActionButtons();
  
  // Показываем информацию о пользователе
  displayUserInfo();
});

// Проверка авторизации
async function checkAuth() {
  try {
    const result = await chrome.storage.local.get([AUTH_TOKEN_KEY, USER_INFO_KEY]);
    authToken = result[AUTH_TOKEN_KEY];
    userInfo = result[USER_INFO_KEY];
    
    if (!authToken) {
      return false;
    }
    
    return true;
  } catch (error) {
    console.error('Auth check error:', error);
    return false;
  }
}

// Получение заголовков для API запросов
function getAuthHeaders() {
  const headers = {
    'Content-Type': 'application/json'
  };
  
  if (authToken === 'guest') {
    headers['X-Guest-Token'] = 'guest';
  } else if (authToken) {
    headers['Authorization'] = `Bearer ${authToken}`;
  }
  
  return headers;
}

// Отображение информации о пользователе
function displayUserInfo() {
  if (userInfo) {
    const username = userInfo.preferred_username || userInfo.sub || 'Guest';
    const header = document.querySelector('.header h1');
    if (header) {
      header.textContent = `🔗 Links Manager (${username})`;
    }
  }
}

// Загрузка настроек
async function loadSettings() {
  const result = await chrome.storage.local.get(['apiUrl']);
  if (result.apiUrl) {
    API_URL = result.apiUrl;
    document.getElementById('apiUrl').value = API_URL;
  }
}

// Сохранение настроек
async function saveSettings() {
  const apiUrl = document.getElementById('apiUrl').value;
  await chrome.storage.local.set({ apiUrl });
  API_URL = apiUrl;
  showMessage('Настройки сохранены', 'success');
  await loadLinks();
}

// Загрузка ссылок
async function loadLinks() {
  try {
    showLoading();
    const response = await fetch(`${API_URL}/api/links`, {
      headers: getAuthHeaders()
    });
    if (!response.ok) {
      if (response.status === 401) {
        // Не авторизован, перенаправляем на страницу авторизации
        window.location.href = 'auth.html';
        return;
      }
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    const links = await response.json();
    currentLinks = Array.isArray(links) ? links : [];
    renderLinks();
    
    // Убираем сообщения об ошибках, если загрузка успешна
    const errorMsg = document.getElementById('linksList')?.querySelector('.error');
    if (errorMsg) {
      errorMsg.remove();
    }
  } catch (error) {
    showError(`Ошибка загрузки: ${error.message}`);
    console.error('Error loading links:', error);
  }
}

// Отображение ссылок
function renderLinks() {
  const container = document.getElementById('linksList');
  const filteredLinks = filterLinks(currentLinks, currentFilter);
  const searchTerm = document.getElementById('searchInput').value.toLowerCase();

  const filtered = searchTerm
    ? filteredLinks.filter(link =>
        link.name?.toLowerCase().includes(searchTerm) ||
        link.url?.toLowerCase().includes(searchTerm) ||
        link.description?.toLowerCase().includes(searchTerm)
      )
    : filteredLinks;

  if (filtered.length === 0) {
    container.innerHTML = '<div class="empty">Нет ссылок</div>';
    return;
  }

  container.innerHTML = filtered.map(link => {
    const linkId = escapeHtml(link.id || '');
    const linkName = escapeHtml(link.name || '');
    const isPublic = link.is_public === true || link.is_public === 1;
    const publicBadge = isPublic ? '<span style="background: #28a745; color: white; padding: 2px 6px; border-radius: 3px; font-size: 10px; margin-left: 5px;">🌐 Публичная</span>' : '';
    const shortLink = isPublic ? `/u/${encodeURIComponent(linkName)}` : `/r/${encodeURIComponent(linkName)}`;
    return `
    <div class="link-item" data-link-id="${linkId}">
      <div class="link-header">
        <div>
          <div class="link-name">${linkName || 'Без названия'}${publicBadge}</div>
          <div class="link-short">${shortLink}</div>
        </div>
        ${link.group_id ? `<span class="link-group">${escapeHtml(link.group_id)}</span>` : ''}
      </div>
      <div class="link-url">${escapeHtml(link.url || '')}</div>
      ${link.description ? `<div class="link-description">${escapeHtml(link.description)}</div>` : ''}
      <div class="link-meta">
        <span>Создано: ${formatDate(link.created_at)}</span>
      </div>
      <div class="link-actions">
        <button class="btn btn-primary btn-small" data-action="open" data-name="${linkName}" title="Открыть ссылку">Открыть</button>
        <button class="btn btn-secondary btn-small" data-action="copy-short" data-name="${linkName}" title="Копировать короткую ссылку (${API_URL}/r/${linkName})">📋</button>
        <button class="btn btn-secondary btn-small" data-action="copy-url" data-url="${escapeHtml(link.url || '')}" title="Копировать полный URL">🔗</button>
        <button class="btn btn-secondary btn-small" data-action="edit" data-id="${linkId}" title="Редактировать ссылку">✏️</button>
        <button class="btn btn-danger btn-small" data-action="delete" data-id="${linkId}" title="Удалить ссылку">🗑️</button>
      </div>
    </div>
  `;
  }).join('');
}

// Фильтрация ссылок
function filterLinks(links, filter) {
  if (filter === 'all') return links;
  return links.filter(link => link.group_id === filter);
}

// Открытие ссылки
async function openLink(name) {
  const url = `${API_URL}/r/${encodeURIComponent(name)}`;
  try {
    // Используем chrome.tabs API для открытия ссылки
    await chrome.tabs.create({ url: url });
  } catch (error) {
    // Fallback на window.open если chrome.tabs недоступен
    console.error('Error opening link:', error);
    window.open(url, '_blank');
  }
}

// Копирование короткой ссылки в буфер обмена
async function copyShortLink(name, isPublic = false) {
  const prefix = isPublic ? '/u/' : '/r/';
  const shortUrl = `${API_URL}${prefix}${encodeURIComponent(name)}`;
  try {
    await navigator.clipboard.writeText(shortUrl);
    showMessage('Короткая ссылка скопирована!', 'success');
  } catch (error) {
    // Fallback для старых браузеров
    try {
      const textArea = document.createElement('textarea');
      textArea.value = shortUrl;
      textArea.style.position = 'fixed';
      textArea.style.left = '-999999px';
      document.body.appendChild(textArea);
      textArea.select();
      document.execCommand('copy');
      document.body.removeChild(textArea);
      showMessage('Короткая ссылка скопирована!', 'success');
    } catch (fallbackError) {
      showError('Не удалось скопировать ссылку');
      console.error('Error copying short link:', fallbackError);
    }
  }
}

// Копирование полного URL в буфер обмена
async function copyUrl(url) {
  try {
    await navigator.clipboard.writeText(url);
    showMessage('URL скопирован!', 'success');
  } catch (error) {
    // Fallback для старых браузеров
    try {
      const textArea = document.createElement('textarea');
      textArea.value = url;
      textArea.style.position = 'fixed';
      textArea.style.left = '-999999px';
      document.body.appendChild(textArea);
      textArea.select();
      document.execCommand('copy');
      document.body.removeChild(textArea);
      showMessage('URL скопирован!', 'success');
    } catch (fallbackError) {
      showError('Не удалось скопировать URL');
      console.error('Error copying URL:', fallbackError);
    }
  }
}

// Редактирование ссылки
async function editLink(id) {
  const link = currentLinks.find(l => l.id === id);
  if (!link) return;

  editingLinkId = id;
  document.getElementById('modalTitle').textContent = 'Редактировать ссылку';
  document.getElementById('linkName').value = link.name || '';
  document.getElementById('linkUrl').value = link.url || '';
  document.getElementById('linkDescription').value = link.description || '';
  document.getElementById('linkGroup').value = link.group_id || '';
  document.getElementById('linkIsPublic').checked = link.is_public === true || link.is_public === 1;
  document.getElementById('linkModal').style.display = 'block';
}

// Удаление ссылки
async function deleteLink(id) {
  if (!confirm('Вы уверены, что хотите удалить эту ссылку?')) return;

  try {
    const response = await fetch(`${API_URL}/api/links/${id}`, {
      method: 'DELETE',
      headers: getAuthHeaders()
    });

    // Проверяем статус ответа
    // 204 (No Content) или 200 - успешное удаление
    // 500 может быть, если сервер не возвращает правильный статус, но удаление произошло
    if (response.status === 204 || response.status === 200) {
      showMessage('Ссылка удалена', 'success');
      await loadLinks();
    } else if (response.status === 500) {
      // Если 500, но возможно удаление произошло, проверяем через небольшую задержку
      showMessage('Удаление...', 'success');
      // Ждем немного и перезагружаем список
      setTimeout(async () => {
        await loadLinks();
        showMessage('Ссылка удалена', 'success');
      }, 500);
    } else {
      // Для других ошибок показываем сообщение
      const errorText = await response.text().catch(() => '');
      throw new Error(`HTTP error! status: ${response.status}${errorText ? ': ' + errorText : ''}`);
    }
  } catch (error) {
    // Если ошибка сети, все равно пытаемся обновить список
    console.error('Error deleting link:', error);
    showMessage('Проверяем удаление...', 'success');
    setTimeout(async () => {
      await loadLinks();
    }, 500);
  }
}

// Создание/обновление ссылки
async function saveLink(formData) {
  // Извлекаем данные из формы (используем name атрибуты или fallback на ID)
  const nameValue = formData.get('name') || document.getElementById('linkName').value || '';
  const urlValue = formData.get('url') || document.getElementById('linkUrl').value || '';
  const descriptionValue = formData.get('description') || document.getElementById('linkDescription').value || '';
  const groupValue = formData.get('group') || document.getElementById('linkGroup').value || '';
  
  const isPublicValue = document.getElementById('linkIsPublic').checked;
  
  const linkData = {
    name: nameValue.trim(),
    url: urlValue.trim(),
    description: descriptionValue.trim(),
    group_id: groupValue,
    is_public: isPublicValue
  };

  // Валидация на клиенте
  if (!linkData.name) {
    showErrorInModal('Имя ссылки обязательно для заполнения');
    document.getElementById('linkName').focus();
    return;
  }

  if (!linkData.url) {
    showErrorInModal('URL обязателен для заполнения');
    document.getElementById('linkUrl').focus();
    return;
  }
  
  // Логируем для отладки
  console.log('Saving link data:', linkData);

  try {
    let response;
    if (editingLinkId) {
      // Обновление
      response = await fetch(`${API_URL}/api/links/${editingLinkId}`, {
        method: 'PUT',
        headers: getAuthHeaders(),
        body: JSON.stringify(linkData)
      });
    } else {
      // Создание
      response = await fetch(`${API_URL}/api/links`, {
        method: 'POST',
        headers: getAuthHeaders(),
        body: JSON.stringify(linkData)
      });
    }

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      
      // Обрабатываем различные типы ошибок
      let errorMessage = 'Ошибка сохранения';
      if (errorData.error === 'name_required' || errorData.message?.includes('name_required')) {
        errorMessage = 'Имя ссылки обязательно для заполнения';
        document.getElementById('linkName').focus();
      } else if (errorData.error === 'name_already_exists' || errorData.message?.includes('name_already_exists')) {
        errorMessage = 'Имя ссылки уже существует. Пожалуйста, выберите другое имя.';
        document.getElementById('linkName').focus();
      } else if (errorData.message) {
        errorMessage = errorData.message;
      } else if (errorData.error) {
        errorMessage = `Ошибка: ${errorData.error}`;
      } else {
        errorMessage = `HTTP error! status: ${response.status}`;
      }
      
      // Показываем ошибку в модальном окне
      showErrorInModal(errorMessage);
      return; // Не закрываем форму при ошибке
    }

    // Успешное сохранение
    showMessage(editingLinkId ? 'Ссылка обновлена' : 'Ссылка создана', 'success');
    closeModal();
    await loadLinks();
  } catch (error) {
    showErrorInModal(`Ошибка сохранения: ${error.message}`);
    console.error('Error saving link:', error);
  }
}

// Закрытие модального окна
function closeModal() {
  // Удаляем сообщения об ошибках при закрытии
  const existingError = document.querySelector('#linkModal .error');
  if (existingError) {
    existingError.remove();
  }
  document.getElementById('linkModal').style.display = 'none';
  document.getElementById('linkForm').reset();
  editingLinkId = null;
}

// Показ ошибки в модальном окне
function showErrorInModal(message) {
  // Удаляем предыдущие сообщения об ошибках
  const existingError = document.querySelector('#linkModal .error');
  if (existingError) {
    existingError.remove();
  }
  
  // Создаем новое сообщение об ошибке
  const errorEl = document.createElement('div');
  errorEl.className = 'error';
  errorEl.textContent = message;
  
  // Вставляем перед формой
  const form = document.getElementById('linkForm');
  form.parentNode.insertBefore(errorEl, form);
  
  // Автоматически удаляем через 5 секунд
  setTimeout(() => {
    if (errorEl.parentNode) {
      errorEl.remove();
    }
  }, 5000);
}

// Заполнение URL текущей страницы при открытии модального окна
async function fillCurrentPageUrl() {
  // Получаем активную вкладку
  try {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    if (tab && tab.url) {
      // Сохраняем URL текущей страницы для использования при создании ссылки
      window.currentPageUrl = tab.url;
      window.currentPageTitle = tab.title || '';
    }
    
    // Проверяем, есть ли отложенная ссылка из контекстного меню
    const result = await chrome.storage.local.get(['pendingLinkUrl', 'pendingLinkTitle']);
    if (result.pendingLinkUrl) {
      window.currentPageUrl = result.pendingLinkUrl;
      window.currentPageTitle = result.pendingLinkTitle || '';
      // Очищаем отложенную ссылку
      await chrome.storage.local.remove(['pendingLinkUrl', 'pendingLinkTitle']);
    }
  } catch (error) {
    console.error('Error getting current tab:', error);
  }
}

// Настройка обработчиков событий
function setupEventListeners() {
  // Кнопка обновления списка
  document.getElementById('reloadBtn').addEventListener('click', async () => {
    await loadLinks();
    showMessage('Список обновлен', 'success');
  });
  
  // Кнопка добавления ссылки
  document.getElementById('addLinkBtn').addEventListener('click', async () => {
    editingLinkId = null;
    document.getElementById('modalTitle').textContent = 'Новая ссылка';
    document.getElementById('linkForm').reset();
    
    // Заполняем URL текущей страницы, если доступен
    if (window.currentPageUrl) {
      document.getElementById('linkUrl').value = window.currentPageUrl;
      // Предзаполняем название на основе заголовка страницы
      if (window.currentPageTitle) {
        const suggestedName = window.currentPageTitle
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, '-')
          .replace(/^-+|-+$/g, '')
          .substring(0, 50);
        document.getElementById('linkName').value = suggestedName;
      }
    }
    
    document.getElementById('linkModal').style.display = 'block';
  });

  // Закрытие модального окна
  document.querySelector('.close').addEventListener('click', () => {
    document.getElementById('linkModal').style.display = 'none';
  });

  document.getElementById('cancelBtn').addEventListener('click', () => {
    document.getElementById('linkModal').style.display = 'none';
  });

  // Форма ссылки
  document.getElementById('linkForm').addEventListener('submit', (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    saveLink(formData);
  });

  // Поиск
  document.getElementById('searchInput').addEventListener('input', renderLinks);

  // Главные табы (Ссылки, Экспорт, Импорт)
  document.querySelectorAll('.tab').forEach(tab => {
    tab.addEventListener('click', () => {
      const tabName = tab.dataset.tab;
      
      // Убираем активность со всех табов
      document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      
      // Показываем/скрываем контент
      document.getElementById('linksList').style.display = tabName === 'links' ? 'block' : 'none';
      document.getElementById('exportContent').style.display = tabName === 'export' ? 'block' : 'none';
      document.getElementById('importContent').style.display = tabName === 'import' ? 'block' : 'none';
      document.getElementById('filterTabs').style.display = tabName === 'links' ? 'flex' : 'none';
      document.getElementById('searchInput').parentElement.style.display = tabName === 'links' ? 'block' : 'none';
      
      // Если выбрана вкладка ссылок, загружаем их
      if (tabName === 'links') {
        loadLinks();
      } else if (tabName === 'export') {
        // При открытии экспорта можно сразу показать текущий экспорт
      } else if (tabName === 'import') {
        // Очищаем поле импорта
        document.getElementById('importData').value = '';
        document.getElementById('importResult').innerHTML = '';
      }
    });
  });
  
  // Фильтры для ссылок
  document.querySelectorAll('.filter-tab').forEach(tab => {
    tab.addEventListener('click', () => {
      document.querySelectorAll('.filter-tab').forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      currentFilter = tab.dataset.filter;
      renderLinks();
    });
  });
  
  // Кнопка экспорта
  document.getElementById('exportBtn').addEventListener('click', exportLinks);
  
  // Кнопка импорта
  document.getElementById('importBtn').addEventListener('click', importLinks);
  
  // Кнопка выхода
  document.getElementById('logoutBtn').addEventListener('click', async () => {
    if (confirm('Вы уверены, что хотите выйти?')) {
      await chrome.storage.local.remove(['auth_token', 'user_info']);
      window.location.href = 'auth.html';
    }
  });
  
  // Кнопка копирования экспорта (делегирование событий, так как кнопка создается динамически)
  document.addEventListener('click', async (e) => {
    if (e.target.id === 'copyExportBtn' || e.target.closest('#copyExportBtn')) {
      e.preventDefault();
      e.stopPropagation();
      await copyExportData();
    }
  });

  // Сохранение настроек
  document.getElementById('saveSettingsBtn').addEventListener('click', saveSettings);
}

// Настройка делегирования событий для кнопок действий (вызывается один раз)
function setupActionButtons() {
  if (actionButtonsSetup) return; // Уже настроено
  
  const linksList = document.getElementById('linksList');
  if (!linksList) return;
  
  // Используем делегирование событий для обработки кликов по кнопкам
  // Это работает для всех динамически созданных элементов
  linksList.addEventListener('click', async (e) => {
    const button = e.target.closest('[data-action]');
    if (!button) return;
    
    e.preventDefault();
    e.stopPropagation();
    
    const action = button.dataset.action;
    const linkId = button.dataset.id;
    const linkName = button.dataset.name;
    const linkUrl = button.dataset.url;
    
    if (action === 'open' && linkName) {
      await openLink(linkName);
    } else if (action === 'copy-short' && linkName) {
      const isPublic = e.target.getAttribute('data-is-public') === 'true';
      await copyShortLink(linkName, isPublic);
    } else if (action === 'copy-url' && linkUrl) {
      await copyUrl(linkUrl);
    } else if (action === 'edit' && linkId) {
      await editLink(linkId);
    } else if (action === 'delete' && linkId) {
      await deleteLink(linkId);
    }
  });
  
  actionButtonsSetup = true;
}

// Утилиты
function showLoading() {
  document.getElementById('linksList').innerHTML = '<div class="loading">Загрузка...</div>';
}

function showError(message) {
  const container = document.getElementById('linksList');
  container.innerHTML = `<div class="error">${escapeHtml(message)}</div>`;
}

function showMessage(message, type = 'success') {
  // Показываем сообщение вверху списка ссылок
  const container = document.getElementById('linksList');
  if (!container) return;
  
  const className = type === 'success' ? 'success' : 'error';
  
  // Удаляем предыдущие сообщения того же типа
  const existingMsg = container.querySelector(`.${className}`);
  if (existingMsg) {
    existingMsg.remove();
  }
  
  const msgEl = document.createElement('div');
  msgEl.className = className;
  msgEl.textContent = message;
  container.insertBefore(msgEl, container.firstChild);
  setTimeout(() => msgEl.remove(), 3000);
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

function formatDate(dateString) {
  if (!dateString) return 'Неизвестно';
  const date = new Date(dateString);
  return date.toLocaleDateString('ru-RU', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  });
}

// Экспорт ссылок в base64
async function exportLinks() {
  try {
    // Загружаем все ссылки
    const response = await fetch(`${API_URL}/api/links`, {
      headers: getAuthHeaders()
    });
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    const links = await response.json();
    
    if (!Array.isArray(links) || links.length === 0) {
      document.getElementById('exportResult').innerHTML = 
        '<div class="error">Нет ссылок для экспорта</div>';
      return;
    }
    
    // Создаем объект экспорта с метаданными
    const exportData = {
      version: '1.0',
      exportDate: new Date().toISOString(),
      count: links.length,
      links: links
    };
    
    // Конвертируем в JSON и затем в base64
    const jsonString = JSON.stringify(exportData, null, 2);
    const base64String = btoa(unescape(encodeURIComponent(jsonString)));
    
    // Показываем результат
    const resultDiv = document.getElementById('exportResult');
    resultDiv.innerHTML = `
      <div class="success">
        <p><strong>Экспортировано ссылок: ${links.length}</strong></p>
        <p>Дата экспорта: ${new Date().toLocaleString('ru-RU')}</p>
      </div>
      <div class="export-box">
        <label>Base64 строка (скопируйте для бэкапа):</label>
        <textarea id="exportBase64" readonly rows="6" style="width: 100%; font-family: monospace; font-size: 11px; padding: 10px; border: 1px solid #ddd; border-radius: 4px; margin-top: 8px;">${base64String}</textarea>
        <button id="copyExportBtn" class="btn btn-secondary btn-small" style="margin-top: 8px;">📋 Копировать</button>
      </div>
    `;
    
    // Добавляем обработчик для кнопки копирования сразу после создания
    const copyBtn = document.getElementById('copyExportBtn');
    if (copyBtn) {
      copyBtn.addEventListener('click', async (e) => {
        e.preventDefault();
        e.stopPropagation();
        await copyExportData();
      });
    }
  } catch (error) {
    document.getElementById('exportResult').innerHTML = 
      `<div class="error">Ошибка экспорта: ${error.message}</div>`;
    console.error('Error exporting links:', error);
  }
}

// Копирование экспортированных данных
async function copyExportData() {
  const textarea = document.getElementById('exportBase64');
  if (!textarea) return;
  
  const textToCopy = textarea.value;
  
  try {
    // Используем современный Clipboard API
    await navigator.clipboard.writeText(textToCopy);
    
    // Показываем сообщение об успехе
    const resultDiv = document.getElementById('exportResult');
    const successMsg = document.createElement('div');
    successMsg.className = 'success';
    successMsg.textContent = '✅ Данные скопированы в буфер обмена!';
    successMsg.style.marginTop = '10px';
    resultDiv.appendChild(successMsg);
    
    // Удаляем сообщение через 3 секунды
    setTimeout(() => {
      if (successMsg.parentNode) {
        successMsg.remove();
      }
    }, 3000);
  } catch (error) {
    // Fallback для старых браузеров
    try {
      textarea.select();
      textarea.setSelectionRange(0, 99999); // Для мобильных устройств
      const successful = document.execCommand('copy');
      
      if (successful) {
        const resultDiv = document.getElementById('exportResult');
        const successMsg = document.createElement('div');
        successMsg.className = 'success';
        successMsg.textContent = '✅ Данные скопированы в буфер обмена!';
        successMsg.style.marginTop = '10px';
        resultDiv.appendChild(successMsg);
        
        setTimeout(() => {
          if (successMsg.parentNode) {
            successMsg.remove();
          }
        }, 3000);
      } else {
        throw new Error('Не удалось скопировать');
      }
    } catch (fallbackError) {
      // Если и fallback не сработал, показываем ошибку
      const resultDiv = document.getElementById('exportResult');
      const errorMsg = document.createElement('div');
      errorMsg.className = 'error';
      errorMsg.textContent = '❌ Не удалось скопировать. Выделите текст вручную и скопируйте (Ctrl+C / Cmd+C)';
      errorMsg.style.marginTop = '10px';
      resultDiv.appendChild(errorMsg);
      
      // Выделяем текст для ручного копирования
      textarea.select();
      textarea.setSelectionRange(0, 99999);
      
      console.error('Error copying to clipboard:', fallbackError);
    }
  }
}

// Импорт ссылок из base64
async function importLinks() {
  const importData = document.getElementById('importData').value.trim();
  const resultDiv = document.getElementById('importResult');
  
  if (!importData) {
    resultDiv.innerHTML = '<div class="error">Введите base64 строку для импорта</div>';
    return;
  }
  
  try {
    // Декодируем base64
    let jsonString;
    try {
      jsonString = decodeURIComponent(escape(atob(importData)));
    } catch (e) {
      throw new Error('Неверный формат base64 строки');
    }
    
    // Парсим JSON
    let importDataObj;
    try {
      importDataObj = JSON.parse(jsonString);
    } catch (e) {
      throw new Error('Неверный формат JSON данных');
    }
    
    // Проверяем структуру данных
    if (!importDataObj.links || !Array.isArray(importDataObj.links)) {
      throw new Error('Неверная структура данных импорта');
    }
    
    const linksToImport = importDataObj.links;
    if (linksToImport.length === 0) {
      resultDiv.innerHTML = '<div class="error">Нет ссылок для импорта</div>';
      return;
    }
    
    // Импортируем ссылки
    let successCount = 0;
    let errorCount = 0;
    const errors = [];
    
    resultDiv.innerHTML = '<div class="loading">Импорт ссылок...</div>';
    
    for (const link of linksToImport) {
      try {
        // Подготавливаем данные ссылки
        const linkData = {
          name: link.name || '',
          url: link.url || '',
          description: link.description || '',
          group_id: link.group_id || ''
        };
        
        // Пропускаем ссылки без обязательных полей
        if (!linkData.name || !linkData.url) {
          errorCount++;
          errors.push(`Ссылка без имени или URL пропущена`);
          continue;
        }
        
        // Пытаемся создать ссылку
        const response = await fetch(`${API_URL}/api/links`, {
          method: 'POST',
          headers: getAuthHeaders(),
          body: JSON.stringify(linkData)
        });
        
        if (response.ok) {
          successCount++;
        } else {
          const errorData = await response.json().catch(() => ({}));
          if (errorData.error === 'name_already_exists') {
            // Ссылка уже существует - это не критическая ошибка
            successCount++;
          } else {
            errorCount++;
            errors.push(`${linkData.name}: ${errorData.message || 'Ошибка создания'}`);
          }
        }
      } catch (error) {
        errorCount++;
        errors.push(`${link.name || 'Неизвестная'}: ${error.message}`);
      }
    }
    
    // Показываем результаты
    let resultHTML = `
      <div class="success">
        <p><strong>Импорт завершен!</strong></p>
        <p>Успешно импортировано: ${successCount} из ${linksToImport.length}</p>
        ${errorCount > 0 ? `<p>Ошибок: ${errorCount}</p>` : ''}
      </div>
    `;
    
    if (errors.length > 0 && errors.length <= 10) {
      resultHTML += `
        <div class="error" style="margin-top: 10px;">
          <strong>Ошибки:</strong>
          <ul style="margin: 8px 0; padding-left: 20px;">
            ${errors.map(e => `<li>${escapeHtml(e)}</li>`).join('')}
          </ul>
        </div>
      `;
    } else if (errors.length > 10) {
      resultHTML += `
        <div class="error" style="margin-top: 10px;">
          <strong>Ошибок слишком много (${errors.length}). Показаны первые 10:</strong>
          <ul style="margin: 8px 0; padding-left: 20px;">
            ${errors.slice(0, 10).map(e => `<li>${escapeHtml(e)}</li>`).join('')}
          </ul>
        </div>
      `;
    }
    
    resultDiv.innerHTML = resultHTML;
    
    // Обновляем список ссылок если были успешные импорты
    if (successCount > 0) {
      setTimeout(() => {
        // Переключаемся на вкладку ссылок и обновляем список
        document.querySelector('[data-tab="links"]').click();
        loadLinks();
      }, 1000);
    }
  } catch (error) {
    resultDiv.innerHTML = `<div class="error">Ошибка импорта: ${error.message}</div>`;
    console.error('Error importing links:', error);
  }
}

// Экспорт функции для использования в HTML
window.copyExportData = copyExportData;
