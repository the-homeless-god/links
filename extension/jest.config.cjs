const path = require('path');

module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'jsdom',
  roots: ['./src'],
  collectCoverage: true,
  coverageReporters: ['json', 'lcov', 'text', 'json-summary'],
  coverageDirectory: 'coverage',
  collectCoverageFrom: [
    'src/**/*.{js,jsx,ts,tsx}',
    '!src/types.ts',
    '!src/config.ts',
    '!src/**/*.d.ts',
    '!src/**/index.ts',
    '!src/tests/**/*',
  ],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  coveragePathIgnorePatterns: ['/node_modules/', '\\.test\\.ts$', '/tests/'],
  coverageProvider: 'v8',
  moduleDirectories: ['node_modules'],
  setupFiles: ['<rootDir>/src/tests/mocks/chrome.ts', '<rootDir>/src/tests/setup.ts'],
  testPathIgnorePatterns: ['/node_modules/'],
  testEnvironmentOptions: {
    url: 'http://localhost/',
  },
  rootDir: __dirname,
  coverageThreshold: {
    global: {
      lines: 60,
      statements: 60,
      branches: 80,
      functions: 50,
    },
  },
  transform: {
    '^.+\\.ts$': [
      'ts-jest',
      {
        tsconfig: {
          esModuleInterop: true,
        },
      },
    ],
  },
};
