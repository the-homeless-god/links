import * as TE from 'fp-ts/TaskEither';
import { STORAGE_KEYS, API_URL_DEFAULT } from '@/config';
import type { UserInfo, KeycloakConfig, AuthState } from '@/types';
import { log } from './logger';

export const getAuthState = (): TE.TaskEither<Error, AuthState> =>
  TE.tryCatch(
    async () => {
      const result = await chrome.storage.local.get([
        STORAGE_KEYS.AUTH_TOKEN,
        STORAGE_KEYS.USER_INFO,
      ]);
      return {
        authToken: result[STORAGE_KEYS.AUTH_TOKEN] || null,
        userInfo: result[STORAGE_KEYS.USER_INFO] || null,
      };
    },
    (error) => new Error(`Failed to get auth state: ${error}`)
  );

export const setAuthState = (token: string, userInfo: UserInfo): TE.TaskEither<Error, void> =>
  TE.tryCatch(
    async () => {
      await chrome.storage.local.set({
        [STORAGE_KEYS.AUTH_TOKEN]: token,
        [STORAGE_KEYS.USER_INFO]: userInfo,
      });
      log.info('Auth state saved');
    },
    (error) => new Error(`Failed to set auth state: ${error}`)
  );

export const clearAuthState = (): TE.TaskEither<Error, void> =>
  TE.tryCatch(
    async () => {
      await chrome.storage.local.remove([STORAGE_KEYS.AUTH_TOKEN, STORAGE_KEYS.USER_INFO]);
      log.info('Auth state cleared');
    },
    (error) => new Error(`Failed to clear auth state: ${error}`)
  );

export const getKeycloakConfig = (): TE.TaskEither<Error, KeycloakConfig | null> =>
  TE.tryCatch(
    async () => {
      const result = await chrome.storage.local.get(STORAGE_KEYS.KEYCLOAK_CONFIG);
      return result[STORAGE_KEYS.KEYCLOAK_CONFIG] || null;
    },
    (error) => new Error(`Failed to get Keycloak config: ${error}`)
  );

export const setKeycloakConfig = (config: KeycloakConfig): TE.TaskEither<Error, void> =>
  TE.tryCatch(
    async () => {
      await chrome.storage.local.set({ [STORAGE_KEYS.KEYCLOAK_CONFIG]: config });
      log.info('Keycloak config saved');
    },
    (error) => new Error(`Failed to set Keycloak config: ${error}`)
  );

export const getApiUrl = (): TE.TaskEither<Error, string> =>
  TE.tryCatch(
    async () => {
      const result = await chrome.storage.local.get(STORAGE_KEYS.API_URL);
      return result[STORAGE_KEYS.API_URL] || API_URL_DEFAULT;
    },
    (error) => new Error(`Failed to get API URL: ${error}`)
  );

export const setApiUrl = (url: string): TE.TaskEither<Error, void> =>
  TE.tryCatch(
    async () => {
      await chrome.storage.local.set({ [STORAGE_KEYS.API_URL]: url });
      log.info('API URL saved', { url });
    },
    (error) => new Error(`Failed to set API URL: ${error}`)
  );

export const getPendingLink = (): TE.TaskEither<Error, { url: string; title: string } | null> =>
  TE.tryCatch(
    async () => {
      const result = await chrome.storage.local.get([
        STORAGE_KEYS.PENDING_LINK_URL,
        STORAGE_KEYS.PENDING_LINK_TITLE,
      ]);
      if (result[STORAGE_KEYS.PENDING_LINK_URL]) {
        return {
          url: result[STORAGE_KEYS.PENDING_LINK_URL],
          title: result[STORAGE_KEYS.PENDING_LINK_TITLE] || '',
        };
      }
      return null;
    },
    (error) => new Error(`Failed to get pending link: ${error}`)
  );

export const clearPendingLink = (): TE.TaskEither<Error, void> =>
  TE.tryCatch(
    async () => {
      await chrome.storage.local.remove([
        STORAGE_KEYS.PENDING_LINK_URL,
        STORAGE_KEYS.PENDING_LINK_TITLE,
      ]);
      log.info('Pending link cleared');
    },
    (error) => new Error(`Failed to clear pending link: ${error}`)
  );
