import { describe, it, expect } from 'vitest';
import path from 'path';
import { fileURLToPath } from 'url';
import { listSourceFiles, readCode } from '../helpers/sourceScan.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const BACKEND_SRC = path.resolve(__dirname, '../../backend/src');
const ROUTES_DIR = path.join(BACKEND_SRC, 'routes');

// Files permitted to reference supabaseAdmin (the service-role client).
// Paths are relative to backend/src.
//
// routes/auth.ts is the one route file on this list, and deliberately so:
// Supabase auth-token operations (refreshSession, resetPasswordForEmail,
// verifyOtp) are only available on the service-role client — there is no user
// client to perform them with, since the caller has no valid session yet. These
// calls exchange and mint tokens; they do not read user rows into the response
// body, which is what the dual-client rule exists to prevent.
const ALLOWED = [
  'lib/supabase.ts',
  'lib/authService.ts',
  'lib/connectService.ts',
  'lib/inviteService.ts',
  'lib/enrollService.ts',
  'lib/empowerService.ts',
  'lib/gemService.ts',
  'lib/roleService.ts',
  'lib/socialService.ts',
  'lib/adminService.ts',
  'lib/candidateService.ts',
  'lib/profileService.ts',
  'lib/xpService.ts',
  'lib/cronService.ts',
  'middleware/auth.ts',
  'middleware/tierGuards.ts',
  'middleware/requireVerified.ts',
  'middleware/requireAdmin.ts',
  // Same class of use as requireAdmin, and the identical query: a membership lookup
  // against public.admin_users whose result decides a 403 and never reaches the response
  // body. It cannot use a user client — admin_users is not readable as the caller.
  'middleware/requireCompassReviewer.ts',
  'routes/auth.ts',
];

// 🔑 MIDDLEWARE IS ENUMERATED, NOT EXEMPT — the second test below scans ALL of backend/src,
// so a new middleware file that touches supabaseAdmin turns this red until someone adds it
// here. That friction IS the check: it forces one human read of whether the new file is an
// authorisation gate (fine) or something that reads user rows into a response (not fine).
// Do not "simplify" this by excluding src/middleware wholesale.
//
// A stale comment in requireAdmin.ts claiming middleware was excluded by design is what
// left requireCompassReviewer.ts off this list on 2026-08-24, and master's suite was red
// from then until 2026-08-27. That comment has been corrected.

const rel = (file: string) => path.relative(BACKEND_SRC, file).split(path.sep).join('/');

describe('Architecture enforcement: dual-client constraint', () => {
  it('no file in src/routes/ imports supabaseAdmin', () => {
    const violations = listSourceFiles(ROUTES_DIR)
      .filter((file) => readCode(file).includes('supabaseAdmin'))
      .map(rel)
      .filter((file) => !ALLOWED.includes(file));

    expect(
      violations,
      `Architecture violation: the following route files reference supabaseAdmin.\n` +
        `Route handlers must use createUserClient() for data that reaches the response body.\n` +
        `supabaseAdmin is permitted only in src/middleware/ and the files in ALLOWED.\n` +
        `Violations:\n${violations.map((v) => `  - ${v}`).join('\n')}`
    ).toHaveLength(0);
  });

  it('supabaseAdmin exists only in expected files', () => {
    const violations = listSourceFiles(BACKEND_SRC)
      .filter((file) => readCode(file).includes('supabaseAdmin'))
      .map(rel)
      .filter((file) => !ALLOWED.includes(file));

    expect(
      violations,
      `Architecture violation: supabaseAdmin found in unexpected files.\n` +
        `Only permitted in:\n${ALLOWED.map((f) => `  - ${f}`).join('\n')}\n` +
        `Violations:\n${violations.map((v) => `  - ${v}`).join('\n')}`
    ).toHaveLength(0);
  });
});
