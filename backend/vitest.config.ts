import { defineConfig } from 'vitest/config';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  test: {
    environment: 'node',
    globals: true,
    include: [
      '../tests/**/*.{test,spec}.{ts,js}',
      'test/**/*.{test,spec}.{ts,js}',
    ],
    testTimeout: 30000,
    hookTimeout: 30000,
    pool: 'forks',
  },
  resolve: {
    alias: {
      '@backend': path.resolve(__dirname, './src'),
      'supertest': path.resolve(__dirname, 'node_modules/supertest'),
    },
  },
});
