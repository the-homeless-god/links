import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
  build: {
    outDir: 'dist',
    emptyOutDir: false,
    lib: {
      entry: resolve(__dirname, 'src/auth/index.ts'),
      formats: ['iife'],
      name: 'auth',
      fileName: 'auth',
    },
    rollupOptions: {
      external: ['chrome'],
      output: {
        entryFileNames: 'auth.js',
        globals: {
          chrome: 'chrome',
        },
      },
    },
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
    },
  },
});
