import { resolve } from 'node:path';
import { defineConfig } from 'vitest/config';

// The demo reads the shared, labelled result fixtures straight from
// contracts/fixtures so the website never drifts from contract v1.
const repoRoot = resolve(__dirname, '../..');

export default defineConfig({
  // Relative base: the built site works from any static host path.
  base: './',
  server: {
    port: 5173,
    fs: { allow: [repoRoot] },
  },
  build: {
    target: 'es2020',
    outDir: 'dist',
    chunkSizeWarningLimit: 700,
  },
  test: {
    environment: 'node',
    include: ['src/**/*.test.ts'],
  },
});
