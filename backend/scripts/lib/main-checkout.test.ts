import { describe, it, expect } from 'vitest';
import { mainCheckoutPlan, shouldRetryFromMain } from './main-checkout.mjs';

// The steward hooks run through ./main-checkout-fallback.mjs so that a linked worktree without
// backend/node_modules (10 of 17 on 2026-09-23) still prints the board, records its marker and runs
// the pathspec observer, instead of skipping all three silently.

const fsWith = (...paths: string[]) => (p: string) => paths.includes(p);

describe('mainCheckoutPlan', () => {
  const commonDir = '/repo/.git';

  it('borrows both from the main checkout when a linked worktree has neither', () => {
    const plan = mainCheckoutPlan({
      here: '/repo/.claude/worktrees/wt/backend', commonDir, platform: 'linux',
      exists: fsWith('/repo/backend/node_modules', '/repo/backend/.env'),
    });
    expect(plan).toEqual({ mainBackend: '/repo/backend', modules: true, env: true });
  });

  it('borrows nothing the worktree already has', () => {
    const plan = mainCheckoutPlan({
      here: '/wt/backend', commonDir, platform: 'linux',
      exists: fsWith('/wt/backend/node_modules', '/wt/backend/.env', '/repo/backend/node_modules', '/repo/backend/.env'),
    });
    expect(plan.modules).toBe(false);
    expect(plan.env).toBe(false);
  });

  it('borrows nothing the main checkout lacks', () => {
    const plan = mainCheckoutPlan({ here: '/wt/backend', commonDir, platform: 'linux', exists: fsWith() });
    expect(plan.modules).toBe(false);
    expect(plan.env).toBe(false);
  });

  // The main checkout must be a no-op, or a missing node_modules there would "borrow" from itself.
  it('is a no-op in the main checkout itself', () => {
    const plan = mainCheckoutPlan({ here: '/repo/backend', commonDir, platform: 'linux', exists: fsWith('/repo/backend/.env') });
    expect(plan).toEqual({ mainBackend: '/repo/backend', modules: false, env: false });
  });

  it('recognises the main checkout on Windows whatever the drive-letter case', () => {
    const plan = mainCheckoutPlan({
      here: 'C:\\EV-Accounts\\backend', commonDir: 'c:/ev-accounts/.git', platform: 'win32',
      exists: () => true,
    });
    expect(plan.modules).toBe(false);
    expect(plan.env).toBe(false);
  });
});

describe('shouldRetryFromMain', () => {
  it('retries bare and scoped package specifiers that were not found', () => {
    expect(shouldRetryFromMain('pg', 'ERR_MODULE_NOT_FOUND')).toBe(true);
    expect(shouldRetryFromMain('dotenv', 'MODULE_NOT_FOUND')).toBe(true);
    expect(shouldRetryFromMain('@supabase/supabase-js', 'ERR_MODULE_NOT_FOUND')).toBe(true);
  });

  it('never retries a specifier that names a file or a builtin', () => {
    for (const s of ['./lib/x.mjs', '../x.mjs', '/abs/x.mjs', 'C:\\x.mjs', 'file:///x.mjs', 'node:fs', 'data:text/javascript,1']) {
      expect(shouldRetryFromMain(s, 'ERR_MODULE_NOT_FOUND')).toBe(false);
    }
  });

  it('never retries an error other than not-found', () => {
    expect(shouldRetryFromMain('pg', 'ERR_PACKAGE_PATH_NOT_EXPORTED')).toBe(false);
    expect(shouldRetryFromMain('pg', undefined)).toBe(false);
  });
});
