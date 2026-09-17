// Env must be set before anything pulls in lib/env.ts, which validates
// process.env at module-evaluation time and calls process.exit(1) on a miss.
// vitest does not load .env — only src/index.ts does, via `import 'dotenv/config'` —
// and this test never imports the app, so it supplies the required vars itself.
process.env['NODE_ENV'] = 'test';
process.env['SUPABASE_URL'] = 'https://test.supabase.co';
process.env['SUPABASE_ANON_KEY'] = 'test-anon-key';
process.env['SUPABASE_SERVICE_ROLE_KEY'] = 'test-service-role-key';
process.env['DATABASE_URL'] = 'postgresql://postgres:password@localhost:5432/postgres';
process.env['ADMIN_INGEST_TOKEN'] = 'test-ingest-token';
process.env['READRANK_TOKEN_SECRET'] = 'test-readrank-secret';

import { describe, it, expect } from 'vitest';

describe('env — identity vault vars', () => {
  it('exposes the vault vars as optional (undefined when unset)', async () => {
    const { env } = await import('./env');
    expect('ID_VAULT_PUBLIC_KEY' in env).toBe(true);
    // In the test environment they are unset:
    expect(env.ID_VAULT_KEY_VERSION === undefined || typeof env.ID_VAULT_KEY_VERSION === 'number').toBe(true);
  });
});
