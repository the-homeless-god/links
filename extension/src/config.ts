export const API_URL_DEFAULT = 'http://localhost:4000';

export const STORAGE_KEYS = {
  AUTH_TOKEN: 'auth_token',
  USER_INFO: 'user_info',
  KEYCLOAK_CONFIG: 'keycloak_config',
  API_URL: 'apiUrl',
  PENDING_LINK_URL: 'pendingLinkUrl',
  PENDING_LINK_TITLE: 'pendingLinkTitle',
} as const;

export const FILTERS = {
  ALL: 'all',
  DEV: 'dev',
  PROD: 'prod',
  PERSONAL: 'personal',
} as const;

export type FilterType = typeof FILTERS[keyof typeof FILTERS];
