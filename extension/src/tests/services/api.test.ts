import * as TE from 'fp-ts/TaskEither';
import { fetchLinks, createLink, getAuthHeaders } from '@/services/api';
import { chrome } from '../mocks/chrome';
import type { Link } from '@/types';

describe('API Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    (global.fetch as jest.Mock).mockClear();
  });

  describe('getAuthHeaders', () => {
    test('should return headers with guest token', async () => {
      (chrome.storage.local.get as jest.Mock).mockResolvedValueOnce({
        auth_token: 'guest',
        user_info: { sub: 'guest' },
      });

      const result = await getAuthHeaders()();

      expect('right' in result).toBe(true);
      if ('right' in result) {
        expect(result.right['X-Guest-Token']).toBe('guest');
        expect(result.right['Content-Type']).toBe('application/json');
      }
    });

    test('should return headers with bearer token', async () => {
      (chrome.storage.local.get as jest.Mock).mockResolvedValueOnce({
        auth_token: 'bearer-token-123',
        user_info: { sub: 'user-123' },
      });

      const result = await getAuthHeaders()();

      expect('right' in result).toBe(true);
      if ('right' in result) {
        expect(result.right['Authorization']).toBe('Bearer bearer-token-123');
        expect(result.right['Content-Type']).toBe('application/json');
      }
    });
  });

  describe('fetchLinks', () => {
    test('should fetch links successfully', async () => {
      const mockLinks: Link[] = [
        { id: '1', name: 'test', url: 'https://example.com' },
      ];

      (global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => mockLinks,
      });

      const result = await fetchLinks()();

      expect('right' in result).toBe(true);
      if ('right' in result) {
        expect(result.right).toEqual(mockLinks);
      }
    });

    test('should handle unauthorized error', async () => {
      (global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: false,
        status: 401,
      });

      const result = await fetchLinks()();

      expect('left' in result).toBe(true);
      if ('left' in result) {
        expect(result.left.message).toContain('UNAUTHORIZED');
      }
    });

    test('should handle other errors', async () => {
      (global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: false,
        status: 500,
      });

      const result = await fetchLinks()();

      expect('left' in result).toBe(true);
      if ('left' in result) {
        expect(result.left.message).toContain('HTTP error');
      }
    });
  });

  describe('createLink', () => {
    test('should create link successfully', async () => {
      const linkData: Partial<Link> = {
        name: 'test',
        url: 'https://example.com',
      };

      const mockLink: Link = {
        id: '1',
        name: 'test',
        url: 'https://example.com',
      };

      (global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => mockLink,
      });

      const result = await createLink(linkData)();

      expect('right' in result).toBe(true);
      if ('right' in result) {
        expect(result.right).toEqual(mockLink);
      }
      expect(global.fetch).toHaveBeenCalledWith(
        expect.stringContaining('/api/links'),
        expect.objectContaining({
          method: 'POST',
          body: JSON.stringify(linkData),
        })
      );
    });
  });
});
