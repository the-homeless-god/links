import * as TE from 'fp-ts/TaskEither';
import { pipe } from 'fp-ts/function';
import * as T from 'fp-ts/Task';
import {
  getAuthState,
  setAuthState,
  clearAuthState,
  getApiUrl,
  setApiUrl,
} from '@/services/storage';
import { chrome } from '../mocks/chrome';
import type { UserInfo } from '@/types';

describe('Storage Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('getAuthState', () => {
    test('should return auth state successfully', async () => {
      const result = await getAuthState()();

      expect('right' in result).toBe(true);
      if ('right' in result) {
        expect(result.right.authToken).toBe('test-token');
        expect(result.right.userInfo).toEqual({
          sub: 'test-user',
          preferred_username: 'test',
        });
      }
    });

    test('should handle errors', async () => {
      (chrome.storage.local.get as jest.Mock).mockRejectedValueOnce(new Error('Storage error'));

      const result = await getAuthState()();

      expect('left' in result).toBe(true);
      if ('left' in result) {
        expect(result.left.message).toContain('Failed to get auth state');
      }
    });
  });

  describe('setAuthState', () => {
    test('should set auth state successfully', async () => {
      const userInfo: UserInfo = { sub: 'user-123', preferred_username: 'testuser' };
      const result = await setAuthState('token-123', userInfo)();

      expect('right' in result).toBe(true);
      expect(chrome.storage.local.set).toHaveBeenCalledWith({
        auth_token: 'token-123',
        user_info: userInfo,
      });
    });
  });

  describe('clearAuthState', () => {
    test('should clear auth state successfully', async () => {
      const result = await clearAuthState()();

      expect('right' in result).toBe(true);
      expect(chrome.storage.local.remove).toHaveBeenCalledWith(['auth_token', 'user_info']);
    });
  });

  describe('getApiUrl', () => {
    test('should return API URL successfully', async () => {
      const result = await getApiUrl()();

      expect('right' in result).toBe(true);
      if ('right' in result) {
        expect(result.right).toBe('http://localhost:4000');
      }
    });
  });

  describe('setApiUrl', () => {
    test('should set API URL successfully', async () => {
      const result = await setApiUrl('http://example.com')();

      expect('right' in result).toBe(true);
      expect(chrome.storage.local.set).toHaveBeenCalledWith({
        apiUrl: 'http://example.com',
      });
    });
  });
});
