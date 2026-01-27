type LogLevel = 'info' | 'warn' | 'error' | 'debug';

const DEBUG_ENABLED = true;
const DEBUG_PREFIX = '[Links Manager]';

const formatMessage = (level: LogLevel, message: string, ..._args: unknown[]): string => {
  return `${DEBUG_PREFIX} [${level.toUpperCase()}] ${message}`;
};

export const log = {
  info: (message: string, ...args: unknown[]): void => {
    if (DEBUG_ENABLED) {
      console.info(formatMessage('info', message), ...args);
    }
  },
  warn: (message: string, ...args: unknown[]): void => {
    if (DEBUG_ENABLED) {
      console.warn(formatMessage('warn', message), ...args);
    }
  },
  error: (message: string, ...args: unknown[]): void => {
    if (DEBUG_ENABLED) {
      console.error(formatMessage('error', message), ...args);
    }
  },
  debug: (message: string, ...args: unknown[]): void => {
    if (DEBUG_ENABLED) {
      console.debug(formatMessage('debug', message), ...args);
    }
  },
};
