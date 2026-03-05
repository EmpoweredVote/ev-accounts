import { describe, it, expect } from 'vitest';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const BACKEND_SRC = path.resolve(__dirname, '../../backend/src');
const ROUTES_DIR = path.join(BACKEND_SRC, 'routes');

function getAllTsFiles(dir: string): string[] {
  const files: string[] = [];
  if (!fs.existsSync(dir)) return files;

  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...getAllTsFiles(fullPath));
    } else if (entry.name.endsWith('.ts')) {
      files.push(fullPath);
    }
  }
  return files;
}

describe('Architecture enforcement: dual-client constraint', () => {
  it('no file in src/routes/ imports supabaseAdmin', () => {
    const routeFiles = getAllTsFiles(ROUTES_DIR);
    const violations: string[] = [];

    for (const file of routeFiles) {
      const content = fs.readFileSync(file, 'utf-8');
      if (content.includes('supabaseAdmin')) {
        violations.push(path.relative(BACKEND_SRC, file));
      }
    }

    if (violations.length > 0) {
      throw new Error(
        `Architecture violation: the following route files reference supabaseAdmin.\n` +
          `Route handlers must use createUserClient() for data that reaches the response body.\n` +
          `supabaseAdmin is permitted only in src/middleware/.\n` +
          `Violations:\n${violations.map((v) => `  - ${v}`).join('\n')}`
      );
    }

    expect(violations).toHaveLength(0);
  });

  it('supabaseAdmin exists only in expected files', () => {
    const allowedFiles = [
      path.join(BACKEND_SRC, 'lib/supabase.ts'),
      path.join(BACKEND_SRC, 'lib/authService.ts'),
      path.join(BACKEND_SRC, 'lib/inviteService.ts'),
      path.join(BACKEND_SRC, 'lib/enrollService.ts'),
      path.join(BACKEND_SRC, 'lib/empowerService.ts'),
      path.join(BACKEND_SRC, 'lib/gemService.ts'),
      path.join(BACKEND_SRC, 'lib/roleService.ts'),
      path.join(BACKEND_SRC, 'lib/socialService.ts'),
      path.join(BACKEND_SRC, 'lib/adminService.ts'),
      path.join(BACKEND_SRC, 'lib/candidateService.ts'),
      path.join(BACKEND_SRC, 'lib/xpService.ts'),
      path.join(BACKEND_SRC, 'lib/cronService.ts'),
      path.join(BACKEND_SRC, 'middleware/auth.ts'),
      path.join(BACKEND_SRC, 'middleware/tierGuards.ts'),
      path.join(BACKEND_SRC, 'middleware/requireVerified.ts'),
      path.join(BACKEND_SRC, 'middleware/requireAdmin.ts'),
    ];

    const allFiles = getAllTsFiles(BACKEND_SRC);
    const violations: string[] = [];

    for (const file of allFiles) {
      const content = fs.readFileSync(file, 'utf-8');
      if (content.includes('supabaseAdmin') && !allowedFiles.includes(file)) {
        violations.push(path.relative(BACKEND_SRC, file));
      }
    }

    if (violations.length > 0) {
      throw new Error(
        `Architecture violation: supabaseAdmin found in unexpected files.\n` +
          `Only permitted in: lib/supabase.ts, lib/authService.ts, middleware/auth.ts, middleware/tierGuards.ts, middleware/requireVerified.ts\n` +
          `Violations:\n${violations.map((v) => `  - ${v}`).join('\n')}`
      );
    }

    expect(violations).toHaveLength(0);
  });
});
