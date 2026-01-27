import * as TE from 'fp-ts/TaskEither';
import * as T from 'fp-ts/Task';
import { pipe } from 'fp-ts/function';
import type { Link, FilterType } from '@/types';
import { FILTERS } from '@/config';
import { fetchLinks, createLink, updateLink, deleteLink, exportLinks, importLinks } from '@/services/api';
import { getAuthState, getApiUrl, setApiUrl, getPendingLink, clearPendingLink } from '@/services/storage';
import { escapeHtml, formatDate, copyToClipboard, showMessage } from '@/utils/dom';
import { log } from '@/services/logger';

// Состояние приложения
let currentLinks: Link[] = [];
let currentFilter: FilterType = FILTERS.ALL;
let editingLinkId: string | null = null;
let actionButtonsSetup = false;
let apiUrl = 'http://localhost:4000';

// Инициализация
document.addEventListener('DOMContentLoaded', async () => {
  // Проверяем авторизацию
  const authResult = await checkAuth();
  if (!authResult) {
    window.location.href = 'auth.html';
    return;
  }

  await loadSettings();
  await loadLinks();
  setupEventListeners();
  await fillCurrentPageUrl();

  setupActionButtons();
  displayUserInfo();
});

// Проверка авторизации
const checkAuth = (): T.Task<boolean> =>
  pipe(
    getAuthState(),
    TE.fold(
      (error) => {
        log.error('Auth check error:', error);
        return T.of(false);
      },
      ({ authToken }) => T.of(!!authToken)
    )
  );

// Отображение информации о пользователе
function displayUserInfo(): void {
  getAuthState().then(({ userInfo }) => {
    if (userInfo) {
      const username = userInfo.preferred_username || userInfo.sub || 'Guest';
      const header = document.querySelector('.header h1');
      if (header) {
        header.textContent = `🔗 Links Manager (${username})`;
      }
    }
  });
}

// Загрузка настроек
async function loadSettings(): Promise<void> {
  apiUrl = await getApiUrl();
  const apiUrlInput = document.getElementById('apiUrl') as HTMLInputElement;
  if (apiUrlInput) {
    apiUrlInput.value = apiUrl;
  }
}

// Сохранение настроек
async function saveSettings(): Promise<void> {
  const apiUrlInput = document.getElementById('apiUrl') as HTMLInputElement;
  if (!apiUrlInput) return;

  const url = apiUrlInput.value;
  await setApiUrl(url);
  apiUrl = url;
  showMessage(getLinksListContainer(), 'Настройки сохранены', 'success');
  await loadLinks();
}

// Загрузка ссылок
const loadLinks = (): T.Task<void> =>
  pipe(
    T.Do,
    T.chain(() => T.fromIO(() => showLoading())),
    T.chain(() => fetchLinks()),
    TE.fold(
      (error) => {
        const errorMessage = error.message;
        if (errorMessage.includes('UNAUTHORIZED')) {
          window.location.href = 'auth.html';
          return T.of(undefined);
        }
        showError(`Ошибка загрузки: ${errorMessage}`);
        log.error('Error loading links:', error);
        return T.of(undefined);
      },
      (links) => {
        currentLinks = links;
        renderLinks();
        const errorMsg = document.getElementById('linksList')?.querySelector('.error');
        if (errorMsg) {
          errorMsg.remove();
        }
        return T.of(undefined);
      }
    )
  );

// Отображение ссылок
function renderLinks(): void {
  const container = getLinksListContainer();
  const filteredLinks = filterLinks(currentLinks, currentFilter);
  const searchInput = document.getElementById('searchInput') as HTMLInputElement;
  const searchTerm = searchInput?.value.toLowerCase() || '';

  const filtered = searchTerm
    ? filteredLinks.filter(
        (link) =>
          link.name?.toLowerCase().includes(searchTerm) ||
          link.url?.toLowerCase().includes(searchTerm) ||
          link.description?.toLowerCase().includes(searchTerm)
      )
    : filteredLinks;

  if (filtered.length === 0) {
    container.innerHTML = '<div class="empty">Нет ссылок</div>';
    return;
  }

  container.innerHTML = filtered
    .map((link) => {
      const linkId = escapeHtml(link.id || '');
      const linkName = escapeHtml(link.name || '');
      const isPublic = link.is_public === true || link.is_public === 1;
      const publicBadge = isPublic
        ? '<span style="background: #28a745; color: white; padding: 2px 6px; border-radius: 3px; font-size: 10px; margin-left: 5px;">🌐 Публичная</span>'
        : '';
      const shortLink = isPublic
        ? `/u/${encodeURIComponent(linkName)}`
        : `/r/${encodeURIComponent(linkName)}`;
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
        <button class="btn btn-secondary btn-small" data-action="copy-short" data-name="${linkName}" data-is-public="${isPublic}" title="Копировать короткую ссылку">📋</button>
        <button class="btn btn-secondary btn-small" data-action="copy-url" data-url="${escapeHtml(link.url || '')}" title="Копировать полный URL">🔗</button>
        <button class="btn btn-secondary btn-small" data-action="edit" data-id="${linkId}" title="Редактировать ссылку">✏️</button>
        <button class="btn btn-danger btn-small" data-action="delete" data-id="${linkId}" title="Удалить ссылку">🗑️</button>
      </div>
    </div>
  `;
    })
    .join('');
}

// Фильтрация ссылок
function filterLinks(links: Link[], filter: FilterType): Link[] {
  if (filter === FILTERS.ALL) return links;
  return links.filter((link) => link.group_id === filter);
}

// Открытие ссылки
async function openLink(name: string): Promise<void> {
  const url = `${apiUrl}/r/${encodeURIComponent(name)}`;
  try {
    await chrome.tabs.create({ url });
  } catch (error) {
    console.error('Error opening link:', error);
    window.open(url, '_blank');
  }
}

// Копирование короткой ссылки
async function copyShortLink(name: string, isPublic = false): Promise<void> {
  const prefix = isPublic ? '/u/' : '/r/';
  const shortUrl = `${apiUrl}${prefix}${encodeURIComponent(name)}`;
  try {
    await copyToClipboard(shortUrl);
    showMessage(getLinksListContainer(), 'Короткая ссылка скопирована!', 'success');
  } catch (error) {
    showError('Не удалось скопировать ссылку');
    console.error('Error copying short link:', error);
  }
}

// Копирование полного URL
async function copyUrl(url: string): Promise<void> {
  try {
    await copyToClipboard(url);
    showMessage(getLinksListContainer(), 'URL скопирован!', 'success');
  } catch (error) {
    showError('Не удалось скопировать URL');
    console.error('Error copying URL:', error);
  }
}

// Редактирование ссылки
async function editLink(id: string): Promise<void> {
  const link = currentLinks.find((l) => l.id === id);
  if (!link) return;

  editingLinkId = id;
  const modalTitle = document.getElementById('modalTitle');
  const linkName = document.getElementById('linkName') as HTMLInputElement;
  const linkUrl = document.getElementById('linkUrl') as HTMLInputElement;
  const linkDescription = document.getElementById('linkDescription') as HTMLTextAreaElement;
  const linkGroup = document.getElementById('linkGroup') as HTMLSelectElement;
  const linkIsPublic = document.getElementById('linkIsPublic') as HTMLInputElement;
  const linkModal = document.getElementById('linkModal');

  if (modalTitle) modalTitle.textContent = 'Редактировать ссылку';
  if (linkName) linkName.value = link.name || '';
  if (linkUrl) linkUrl.value = link.url || '';
  if (linkDescription) linkDescription.value = link.description || '';
  if (linkGroup) linkGroup.value = link.group_id || '';
  if (linkIsPublic) linkIsPublic.checked = link.is_public === true || link.is_public === 1;
  if (linkModal) linkModal.style.display = 'block';
}

// Удаление ссылки
async function deleteLinkHandler(id: string): Promise<void> {
  if (!confirm('Вы уверены, что хотите удалить эту ссылку?')) return;

  try {
    await deleteLink(id);
    showMessage(getLinksListContainer(), 'Ссылка удалена', 'success');
    await loadLinks();
  } catch (error) {
    console.error('Error deleting link:', error);
    showMessage(getLinksListContainer(), 'Проверяем удаление...', 'success');
    setTimeout(async () => {
      await loadLinks();
    }, 500);
  }
}

// Создание/обновление ссылки
async function saveLink(formData: FormData): Promise<void> {
  const linkNameInput = document.getElementById('linkName') as HTMLInputElement;
  const linkUrlInput = document.getElementById('linkUrl') as HTMLInputElement;
  const linkDescriptionInput = document.getElementById('linkDescription') as HTMLTextAreaElement;
  const linkGroupInput = document.getElementById('linkGroup') as HTMLSelectElement;
  const linkIsPublicInput = document.getElementById('linkIsPublic') as HTMLInputElement;

  const nameValue = formData.get('name') || linkNameInput?.value || '';
  const urlValue = formData.get('url') || linkUrlInput?.value || '';
  const descriptionValue = formData.get('description') || linkDescriptionInput?.value || '';
  const groupValue = formData.get('group') || linkGroupInput?.value || '';
  const isPublicValue = linkIsPublicInput?.checked || false;

  const linkData: Partial<Link> = {
    name: nameValue.toString().trim(),
    url: urlValue.toString().trim(),
    description: descriptionValue.toString().trim(),
    group_id: groupValue.toString(),
    is_public: isPublicValue,
  };

  if (!linkData.name) {
    showErrorInModal('Имя ссылки обязательно для заполнения');
    linkNameInput?.focus();
    return;
  }

  if (!linkData.url) {
    showErrorInModal('URL обязателен для заполнения');
    linkUrlInput?.focus();
    return;
  }

  try {
    if (editingLinkId) {
      await updateLink(editingLinkId, linkData);
      showMessage(getLinksListContainer(), 'Ссылка обновлена', 'success');
    } else {
      await createLink(linkData);
      showMessage(getLinksListContainer(), 'Ссылка создана', 'success');
    }
    closeModal();
    await loadLinks();
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    showErrorInModal(`Ошибка сохранения: ${errorMessage}`);
    console.error('Error saving link:', error);
  }
}

// Закрытие модального окна
function closeModal(): void {
  const existingError = document.querySelector('#linkModal .error');
  if (existingError) {
    existingError.remove();
  }
  const linkModal = document.getElementById('linkModal');
  const linkForm = document.getElementById('linkForm') as HTMLFormElement;
  if (linkModal) linkModal.style.display = 'none';
  if (linkForm) linkForm.reset();
  editingLinkId = null;
}

// Показ ошибки в модальном окне
function showErrorInModal(message: string): void {
  const existingError = document.querySelector('#linkModal .error');
  if (existingError) {
    existingError.remove();
  }

  const errorEl = document.createElement('div');
  errorEl.className = 'error';
  errorEl.textContent = message;

  const form = document.getElementById('linkForm');
  if (form && form.parentNode) {
    form.parentNode.insertBefore(errorEl, form);
  }

  setTimeout(() => {
    if (errorEl.parentNode) {
      errorEl.remove();
    }
  }, 5000);
}

// Заполнение URL текущей страницы
async function fillCurrentPageUrl(): Promise<void> {
  try {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    if (tab && tab.url) {
      (window as unknown as { currentPageUrl?: string }).currentPageUrl = tab.url;
      (window as unknown as { currentPageTitle?: string }).currentPageTitle = tab.title || '';
    }

    const pendingLink = await getPendingLink();
    if (pendingLink) {
      (window as unknown as { currentPageUrl?: string }).currentPageUrl = pendingLink.url;
      (window as unknown as { currentPageTitle?: string }).currentPageTitle = pendingLink.title;
      await clearPendingLink();
    }
  } catch (error) {
    console.error('Error getting current tab:', error);
  }
}

// Настройка обработчиков событий
function setupEventListeners(): void {
  const reloadBtn = document.getElementById('reloadBtn');
  const addLinkBtn = document.getElementById('addLinkBtn');
  const closeBtn = document.querySelector('.close');
  const cancelBtn = document.getElementById('cancelBtn');
  const linkForm = document.getElementById('linkForm');
  const searchInput = document.getElementById('searchInput');
  const exportBtn = document.getElementById('exportBtn');
  const importBtn = document.getElementById('importBtn');
  const logoutBtn = document.getElementById('logoutBtn');
  const saveSettingsBtn = document.getElementById('saveSettingsBtn');

  if (reloadBtn) {
    reloadBtn.addEventListener('click', async () => {
      await loadLinks();
      showMessage(getLinksListContainer(), 'Список обновлен', 'success');
    });
  }

  if (addLinkBtn) {
    addLinkBtn.addEventListener('click', async () => {
      editingLinkId = null;
      const modalTitle = document.getElementById('modalTitle');
      const linkForm = document.getElementById('linkForm') as HTMLFormElement;
      const linkUrl = document.getElementById('linkUrl') as HTMLInputElement;
      const linkName = document.getElementById('linkName') as HTMLInputElement;
      const linkModal = document.getElementById('linkModal');

      if (modalTitle) modalTitle.textContent = 'Новая ссылка';
      if (linkForm) linkForm.reset();

      const currentPageUrl = (window as unknown as { currentPageUrl?: string }).currentPageUrl;
      const currentPageTitle = (window as unknown as { currentPageTitle?: string }).currentPageTitle;

      if (currentPageUrl && linkUrl) {
        linkUrl.value = currentPageUrl;
        if (currentPageTitle && linkName) {
          const suggestedName = currentPageTitle
            .toLowerCase()
            .replace(/[^a-z0-9]+/g, '-')
            .replace(/^-+|-+$/g, '')
            .substring(0, 50);
          linkName.value = suggestedName;
        }
      }

      if (linkModal) linkModal.style.display = 'block';
    });
  }

  if (closeBtn) {
    closeBtn.addEventListener('click', () => {
      const linkModal = document.getElementById('linkModal');
      if (linkModal) linkModal.style.display = 'none';
    });
  }

  if (cancelBtn) {
    cancelBtn.addEventListener('click', () => {
      const linkModal = document.getElementById('linkModal');
      if (linkModal) linkModal.style.display = 'none';
    });
  }

  if (linkForm) {
    linkForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const formData = new FormData(e.target as HTMLFormElement);
      saveLink(formData);
    });
  }

  if (searchInput) {
    searchInput.addEventListener('input', renderLinks);
  }

  // Главные табы
  document.querySelectorAll('.tab').forEach((tab) => {
    tab.addEventListener('click', () => {
      const tabName = tab.getAttribute('data-tab');
      if (!tabName) return;

      document.querySelectorAll('.tab').forEach((t) => t.classList.remove('active'));
      tab.classList.add('active');

      const linksList = document.getElementById('linksList');
      const exportContent = document.getElementById('exportContent');
      const importContent = document.getElementById('importContent');
      const filterTabs = document.getElementById('filterTabs');
      const searchBox = searchInput?.parentElement;

      if (linksList) linksList.style.display = tabName === 'links' ? 'block' : 'none';
      if (exportContent) exportContent.style.display = tabName === 'export' ? 'block' : 'none';
      if (importContent) importContent.style.display = tabName === 'import' ? 'block' : 'none';
      if (filterTabs) filterTabs.style.display = tabName === 'links' ? 'flex' : 'none';
      if (searchBox) searchBox.style.display = tabName === 'links' ? 'block' : 'none';

      if (tabName === 'links') {
        loadLinks();
      } else if (tabName === 'import') {
        const importData = document.getElementById('importData') as HTMLTextAreaElement;
        const importResult = document.getElementById('importResult');
        if (importData) importData.value = '';
        if (importResult) importResult.innerHTML = '';
      }
    });
  });

  // Фильтры для ссылок
  document.querySelectorAll('.filter-tab').forEach((tab) => {
    tab.addEventListener('click', () => {
      document.querySelectorAll('.filter-tab').forEach((t) => t.classList.remove('active'));
      tab.classList.add('active');
      const filter = tab.getAttribute('data-filter') as FilterType;
      if (filter) {
        currentFilter = filter;
        renderLinks();
      }
    });
  });

  if (exportBtn) {
    exportBtn.addEventListener('click', exportLinksHandler);
  }

  if (importBtn) {
    importBtn.addEventListener('click', importLinksHandler);
  }

  if (logoutBtn) {
    logoutBtn.addEventListener('click', async () => {
      if (confirm('Вы уверены, что хотите выйти?')) {
        const { clearAuthState } = await import('@/services/storage');
        await clearAuthState();
        window.location.href = 'auth.html';
      }
    });
  }

  if (saveSettingsBtn) {
    saveSettingsBtn.addEventListener('click', saveSettings);
  }

  // Кнопка копирования экспорта
  document.addEventListener('click', async (e) => {
    const target = e.target as HTMLElement;
    if (target.id === 'copyExportBtn' || target.closest('#copyExportBtn')) {
      e.preventDefault();
      e.stopPropagation();
      await copyExportData();
    }
  });
}

// Настройка делегирования событий для кнопок действий
function setupActionButtons(): void {
  if (actionButtonsSetup) return;

  const linksList = document.getElementById('linksList');
  if (!linksList) return;

  linksList.addEventListener('click', async (e) => {
    const button = (e.target as HTMLElement).closest('[data-action]') as HTMLElement;
    if (!button) return;

    e.preventDefault();
    e.stopPropagation();

    const action = button.getAttribute('data-action');
    const linkId = button.getAttribute('data-id');
    const linkName = button.getAttribute('data-name');
    const linkUrl = button.getAttribute('data-url');
    const isPublic = button.getAttribute('data-is-public') === 'true';

    if (action === 'open' && linkName) {
      await openLink(linkName);
    } else if (action === 'copy-short' && linkName) {
      await copyShortLink(linkName, isPublic);
    } else if (action === 'copy-url' && linkUrl) {
      await copyUrl(linkUrl);
    } else if (action === 'edit' && linkId) {
      await editLink(linkId);
    } else if (action === 'delete' && linkId) {
      await deleteLinkHandler(linkId);
    }
  });

  actionButtonsSetup = true;
}

// Утилиты
function getLinksListContainer(): HTMLElement {
  const container = document.getElementById('linksList');
  if (!container) {
    throw new Error('linksList container not found');
  }
  return container;
}

function showLoading(): void {
  getLinksListContainer().innerHTML = '<div class="loading">Загрузка...</div>';
}

function showError(message: string): void {
  const container = getLinksListContainer();
  container.innerHTML = `<div class="error">${escapeHtml(message)}</div>`;
}

// Экспорт ссылок
async function exportLinksHandler(): Promise<void> {
  try {
    const exportData = await exportLinks();

    if (exportData.links.length === 0) {
      const exportResult = document.getElementById('exportResult');
      if (exportResult) {
        exportResult.innerHTML = '<div class="error">Нет ссылок для экспорта</div>';
      }
      return;
    }

    const jsonString = JSON.stringify(exportData, null, 2);
    const base64String = btoa(unescape(encodeURIComponent(jsonString)));

    const resultDiv = document.getElementById('exportResult');
    if (!resultDiv) return;

    resultDiv.innerHTML = `
      <div class="success">
        <p><strong>Экспортировано ссылок: ${exportData.links.length}</strong></p>
        <p>Дата экспорта: ${new Date().toLocaleString('ru-RU')}</p>
      </div>
      <div class="export-box">
        <label>Base64 строка (скопируйте для бэкапа):</label>
        <textarea id="exportBase64" readonly rows="6" style="width: 100%; font-family: monospace; font-size: 11px; padding: 10px; border: 1px solid #ddd; border-radius: 4px; margin-top: 8px;">${base64String}</textarea>
        <button id="copyExportBtn" class="btn btn-secondary btn-small" style="margin-top: 8px;">📋 Копировать</button>
      </div>
    `;

    const copyBtn = document.getElementById('copyExportBtn');
    if (copyBtn) {
      copyBtn.addEventListener('click', async (e) => {
        e.preventDefault();
        e.stopPropagation();
        await copyExportData();
      });
    }
  } catch (error) {
    const exportResult = document.getElementById('exportResult');
    if (exportResult) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      exportResult.innerHTML = `<div class="error">Ошибка экспорта: ${errorMessage}</div>`;
    }
    console.error('Error exporting links:', error);
  }
}

// Копирование экспортированных данных
async function copyExportData(): Promise<void> {
  const textarea = document.getElementById('exportBase64') as HTMLTextAreaElement;
  if (!textarea) return;

  const textToCopy = textarea.value;

  try {
    await copyToClipboard(textToCopy);

    const resultDiv = document.getElementById('exportResult');
    if (!resultDiv) return;

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
  } catch (error) {
    const resultDiv = document.getElementById('exportResult');
    if (!resultDiv) return;

    const errorMsg = document.createElement('div');
    errorMsg.className = 'error';
    errorMsg.textContent = '❌ Не удалось скопировать. Выделите текст вручную и скопируйте (Ctrl+C / Cmd+C)';
    errorMsg.style.marginTop = '10px';
    resultDiv.appendChild(errorMsg);

    textarea.select();
    textarea.setSelectionRange(0, 99999);

    console.error('Error copying to clipboard:', error);
  }
}

// Импорт ссылок
async function importLinksHandler(): Promise<void> {
  const importData = document.getElementById('importData') as HTMLTextAreaElement;
  const resultDiv = document.getElementById('importResult');

  if (!importData || !resultDiv) return;

  const importDataValue = importData.value.trim();

  if (!importDataValue) {
    resultDiv.innerHTML = '<div class="error">Введите base64 строку для импорта</div>';
    return;
  }

  try {
    let jsonString: string;
    try {
      jsonString = decodeURIComponent(escape(atob(importDataValue)));
    } catch (e) {
      throw new Error('Неверный формат base64 строки');
    }

    let importDataObj: { links?: Link[] };
    try {
      importDataObj = JSON.parse(jsonString);
    } catch (e) {
      throw new Error('Неверный формат JSON данных');
    }

    if (!importDataObj.links || !Array.isArray(importDataObj.links)) {
      throw new Error('Неверная структура данных импорта');
    }

    const linksToImport = importDataObj.links;
    if (linksToImport.length === 0) {
      resultDiv.innerHTML = '<div class="error">Нет ссылок для импорта</div>';
      return;
    }

    resultDiv.innerHTML = '<div class="loading">Импорт ссылок...</div>';

    const { success, errors } = await importLinks(linksToImport);

    let resultHTML = `
      <div class="success">
        <p><strong>Импорт завершен!</strong></p>
        <p>Успешно импортировано: ${success} из ${linksToImport.length}</p>
        ${errors.length > 0 ? `<p>Ошибок: ${errors.length}</p>` : ''}
      </div>
    `;

    if (errors.length > 0 && errors.length <= 10) {
      resultHTML += `
        <div class="error" style="margin-top: 10px;">
          <strong>Ошибки:</strong>
          <ul style="margin: 8px 0; padding-left: 20px;">
            ${errors.map((e) => `<li>${escapeHtml(e)}</li>`).join('')}
          </ul>
        </div>
      `;
    } else if (errors.length > 10) {
      resultHTML += `
        <div class="error" style="margin-top: 10px;">
          <strong>Ошибок слишком много (${errors.length}). Показаны первые 10:</strong>
          <ul style="margin: 8px 0; padding-left: 20px;">
            ${errors.slice(0, 10).map((e) => `<li>${escapeHtml(e)}</li>`).join('')}
          </ul>
        </div>
      `;
    }

    resultDiv.innerHTML = resultHTML;

    if (success > 0) {
      setTimeout(() => {
        const linksTab = document.querySelector('[data-tab="links"]') as HTMLElement;
        if (linksTab) linksTab.click();
        loadLinks();
      }, 1000);
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    if (resultDiv) {
      resultDiv.innerHTML = `<div class="error">Ошибка импорта: ${errorMessage}</div>`;
    }
    console.error('Error importing links:', error);
  }
}
