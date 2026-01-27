import { escapeHtml, formatDate, copyToClipboard, showMessage } from '@/utils/dom';

describe('DOM Utils', () => {
  describe('escapeHtml', () => {
    test('should escape HTML special characters', () => {
      expect(escapeHtml('<script>alert("xss")</script>')).toBe(
        '&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;'
      );
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
      expect(formatted).toMatch(/\d{1,2}\s\w{3}\s\d{4}/);
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
