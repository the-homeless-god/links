export interface Link {
  id: string;
  name: string;
  url: string;
  description?: string;
  group_id?: string;
  is_public?: boolean;
  created_at?: string;
  user_id?: string;
}

export interface UserInfo {
  sub: string;
  user_id?: string;
  preferred_username?: string;
  [key: string]: unknown;
}

export interface KeycloakConfig {
  url: string;
  realm: string;
  clientId: string;
}

export interface ExportData {
  version: string;
  exportDate: string;
  count: number;
  links: Link[];
}

export interface AuthState {
  authToken: string | null;
  userInfo: UserInfo | null;
}

export type MessageType = 'createLinkFromPage';

export interface Message {
  action: MessageType;
}

// Re-export FilterType from config
export type { FilterType } from '@/config';
