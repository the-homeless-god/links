import { escapeHtml, formatDate, copyToClipboard, showMessage } from '@/utils/dom';

describe('DOM Utils', () => {
  describe('escapeHtml', () => {
    test('should escape HTML special characters', () => {
      const result = escapeHtml('<script>alert("xss")</script>');
      // Проверяем, что основные HTML символы экранированы
      expect(result).toContain('&lt;script&gt;');
      expect(result).toContain('&lt;/script&gt;');
      // Кавычки могут быть экранированы по-разному в зависимости от браузера
      // Главное - что скрипт не выполнится
      expect(result).not.toContain('<script>');
      expect(result).not.toContain('</script>');
    });

    test('should handle empty string', () => {
      expect(escapeHtml('')).toBe('');
    });

    test('should handle normal text', () => {
      expect(escapeHtml('Hello World')).toBe('Hello World');
    });
  });

  describe('formatDate', () => {
    test('should format date correctly', () => {
      const date = '2024-01-15T10:30:00Z';
      const formatted = formatDate(date);
      // Формат ru-RU может включать точку и "г.", проверяем основные части
      expect(formatted).toContain('15');
      expect(formatted).toContain('янв');
      expect(formatted).toContain('2024');
      expect(formatted).not.toBe('Неизвестно');
    });

    test('should handle undefined date', () => {
      expect(formatDate(undefined)).toBe('Неизвестно');
    });
  });

  describe('copyToClipboard', () => {
    test('should copy text to clipboard', async () => {
      const mockWriteText = jest.fn().mockResolvedValue(undefined);
      Object.assign(navigator, {
        clipboard: {
          writeText: mockWriteText,
        },
      });

      await copyToClipboard('test text');

      expect(mockWriteText).toHaveBeenCalledWith('test text');
    });

    test('should use fallback for older browsers', async () => {
      const mockExecCommand = jest.fn().mockReturnValue(true);
      document.execCommand = mockExecCommand;

      Object.assign(navigator, {
        clipboard: undefined,
      });

      await copyToClipboard('test text');

      expect(mockExecCommand).toHaveBeenCalledWith('copy');
    });
  });

  describe('showMessage', () => {
    beforeEach(() => {
      document.body.innerHTML = '<div id="container"></div>';
    });

    test('should show success message', () => {
      const container = document.getElementById('container');
      if (!container) return;

      showMessage(container, 'Success!', 'success');

      const message = container.querySelector('.success');
      expect(message).toBeTruthy();
      expect(message?.textContent).toBe('Success!');
    });

    test('should show error message', () => {
      const container = document.getElementById('container');
      if (!container) return;

      showMessage(container, 'Error!', 'error');

      const message = container.querySelector('.error');
      expect(message).toBeTruthy();
      expect(message?.textContent).toBe('Error!');
    });

    test('should remove previous messages of same type', () => {
      const container = document.getElementById('container');
      if (!container) return;

      showMessage(container, 'First', 'success');
      showMessage(container, 'Second', 'success');

      const messages = container.querySelectorAll('.success');
      expect(messages.length).toBe(1);
      expect(messages[0]?.textContent).toBe('Second');
    });
  });
});
