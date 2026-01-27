import { STORAGE_KEYS, API_URL_DEFAULT } from '@/config';
import { Mock } from 'jest-mock';

type StorageCallback = (items: { [key: string]: unknown }) => void;

type ChromeMock = {
  storage: {
    local: {
      get: Mock<
        (_keys: string[], callback?: StorageCallback) => Promise<{ [key: string]: unknown }>
      >;
      set: Mock<(_items: { [key: string]: unknown }) => Promise<void>>;
      remove: Mock<(_keys: string[]) => Promise<void>>;
    };
  };
  runtime: {
    onMessage: {
      addListener: Mock;
    };
    sendMessage: Mock;
  };
  action: {
    onClicked: {
      addListener: Mock;
    };
    openPopup: Mock;
  };
  contextMenus: {
    create: Mock;
    onClicked: {
      addListener: Mock;
    };
  };
  tabs: {
    query: Mock;
    create: Mock;
  };
};

export const createMockStorage = (): {
  local: {
    get: Mock<(_keys: string[]) => Promise<{ [key: string]: unknown }>>;
    set: Mock<(_items: { [key: string]: unknown }) => Promise<void>>;
    remove: Mock<(_keys: string[]) => Promise<void>>;
  };
} => ({
  local: {
    get: jest.fn((_keys: string[]) => {
      return Promise.resolve({
        [STORAGE_KEYS.AUTH_TOKEN]: 'test-token',
        [STORAGE_KEYS.USER_INFO]: { sub: 'test-user', preferred_username: 'test' },
        [STORAGE_KEYS.API_URL]: API_URL_DEFAULT,
      });
    }),
    set: jest.fn((_items: { [key: string]: unknown }) => {
      return Promise.resolve();
    }),
    remove: jest.fn((_keys: string[]) => {
      return Promise.resolve();
    }),
  },
});

const createMockRuntime = (): {
  sendMessage: Mock<(_message: unknown) => Promise<void>>;
  onMessage: { addListener: Mock };
} => ({
  sendMessage: jest.fn((_message: unknown) => Promise.resolve()),
  onMessage: {
    addListener: jest.fn(),
  },
});

const createMockTabs = (): {
  query: Mock<() => Promise<Array<{ id: number; url: string; title: string }>>>;
  create: Mock<() => Promise<{ id: number }>>;
} => ({
  query: jest.fn(() => Promise.resolve([{ id: 1, url: 'https://example.com', title: 'Test' }])),
  create: jest.fn(() => Promise.resolve({ id: 1 })),
});

const createMockAction = (): {
  openPopup: Mock;
  onClicked: { addListener: Mock };
} => ({
  openPopup: jest.fn(),
  onClicked: {
    addListener: jest.fn(),
  },
});

const createMockContextMenus = (): {
  create: Mock;
  onClicked: { addListener: Mock };
} => ({
  create: jest.fn(),
  onClicked: {
    addListener: jest.fn(),
  },
});

export const chrome = {
  storage: createMockStorage(),
  runtime: createMockRuntime(),
  tabs: createMockTabs(),
  action: createMockAction(),
  contextMenus: createMockContextMenus(),
} as unknown as ChromeMock;

// @ts-expect-error - Chrome mock is not fully typed
global.chrome = chrome;

export default chrome;
