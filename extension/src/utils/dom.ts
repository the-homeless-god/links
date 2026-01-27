export function escapeHtml(text: string): string {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

export function formatDate(dateString: string | undefined): string {
  if (!dateString) return 'Неизвестно';
  const date = new Date(dateString);
  return date.toLocaleDateString('ru-RU', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
}

export async function copyToClipboard(text: string): Promise<void> {
  try {
    await navigator.clipboard.writeText(text);
  } catch (_error) {
    // Fallback для старых браузеров
    const textArea = document.createElement('textarea');
    textArea.value = text;
    textArea.style.position = 'fixed';
    textArea.style.left = '-999999px';
    document.body.appendChild(textArea);
    textArea.select();
    textArea.setSelectionRange(0, 99999); // Для мобильных устройств
    const successful = document.execCommand('copy');
    document.body.removeChild(textArea);

    if (!successful) {
      throw new Error('Не удалось скопировать');
    }
  }
}

export function showMessage(
  container: HTMLElement,
  message: string,
  type: 'success' | 'error' = 'success'
): void {
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
