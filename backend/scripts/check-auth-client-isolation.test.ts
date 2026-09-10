import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// Same shape as check-suppressed-answer-reads.test.ts: build a real src/ tree in
// a temp dir and run the guard as a subprocess, exactly as CI does.
//
// The failure mode that matters is the false green — a session-establishing call
// on a shared data client that compiles, passes unit tests, and only denies
// service_role after a login at runtime (the 2026-09-10 compass-write outage).
// Each case pins one direction of that decision.

const SCRIPT = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  'check-auth-client-isolation.mjs'
);

let root: string;
beforeAll(() => { root = mkdtempSync(path.join(tmpdir(), 'authisolation-')); });
afterAll(() => { rmSync(root, { recursive: true, force: true }); });

let n = 0;
/** Write a one-file src/ tree in a fresh dir and run the guard against it. */
function run(contents: string, file = 'lib/subject.ts'): { code: number; out: string } {
  const dir = path.join(root, `case-${++n}`);
  const target = path.join(dir, 'src', file);
  mkdirSync(path.dirname(target), { recursive: true });
  writeFileSync(target, contents, 'utf8');
  const r = spawnSync('node', [SCRIPT], { cwd: dir, encoding: 'utf8' });
  return { code: r.status ?? -1, out: `${r.stdout ?? ''}${r.stderr ?? ''}` };
}

describe('check-auth-client-isolation — it must fail', () => {
  it('signInWithPassword on supabaseAdmin (the outage)', () => {
    const r = run(
      "import { supabaseAdmin } from './supabase.js';\n" +
      'export const f = (e: string, p: string) => supabaseAdmin.auth.signInWithPassword({ email: e, password: p });\n'
    );
    expect(r.code).toBe(1);
    expect(r.out).toContain('supabaseAdmin.auth.signInWithPassword');
  });

  it('signUp on supabaseAnon', () => {
    const r = run(
      "import { supabaseAnon } from './supabase.js';\n" +
      'export const f = (e: string, p: string) => supabaseAnon.auth.signUp({ email: e, password: p });\n'
    );
    expect(r.code).toBe(1);
  });

  it('refreshSession on supabaseService (vq)', () => {
    const r = run(
      "import { supabaseService } from './supabase.js';\n" +
      'export const f = (t: string) => supabaseService.auth.refreshSession({ refresh_token: t });\n'
    );
    expect(r.code).toBe(1);
  });

  it('verifyOtp on supabaseAdmin', () => {
    const r = run(
      "import { supabaseAdmin } from './supabase.js';\n" +
      "export const f = (h: string) => supabaseAdmin.auth.verifyOtp({ token_hash: h, type: 'recovery' });\n"
    );
    expect(r.code).toBe(1);
  });

  it('reports the line, so the reader can jump to it', () => {
    const r = run(
      "import { supabaseAdmin } from './supabase.js';\n" +
      'export const f = (e: string, p: string) => supabaseAdmin.auth.signInWithPassword({ email: e, password: p });\n'
    );
    expect(r.out).toMatch(/lib\/subject\.ts:\d+/);
  });

  // The unit of matching is the call, not the file. Moving one to supabaseAuth
  // must not excuse another left on the shared client in the same file.
  it('a fixed call does not excuse an unfixed one in the same file', () => {
    const r = run(
      "import { supabaseAdmin, supabaseAuth } from './supabase.js';\n" +
      'export const good = (e: string, p: string) => supabaseAuth.auth.signInWithPassword({ email: e, password: p });\n' +
      'export const bad  = (t: string) => supabaseAdmin.auth.refreshSession({ refresh_token: t });\n'
    );
    expect(r.code).toBe(1);
    expect(r.out).toContain('1 session call(s)');
  });
});

describe('check-auth-client-isolation — it must pass', () => {
  it('a session call on the dedicated supabaseAuth client', () => {
    const r = run(
      "import { supabaseAuth } from './supabase.js';\n" +
      'export const f = (e: string, p: string) => supabaseAuth.auth.signInWithPassword({ email: e, password: p });\n'
    );
    expect(r.code).toBe(0);
  });

  it('auth.admin.* on supabaseAdmin — admin calls store no session', () => {
    const r = run(
      "import { supabaseAdmin } from './supabase.js';\n" +
      'export const f = (id: string) => supabaseAdmin.auth.admin.getUserById(id);\n'
    );
    expect(r.code).toBe(0);
  });

  it('auth.getUser(token) on supabaseAdmin — introspection stores no session', () => {
    const r = run(
      "import { supabaseAdmin } from './supabase.js';\n" +
      'export const f = (t: string) => supabaseAdmin.auth.getUser(t);\n'
    );
    expect(r.code).toBe(0);
  });

  it('resetPasswordForEmail / resend on supabaseAdmin — not session methods', () => {
    const r = run(
      "import { supabaseAdmin } from './supabase.js';\n" +
      'export const a = (e: string) => supabaseAdmin.auth.resetPasswordForEmail(e);\n' +
      "export const b = (e: string) => supabaseAdmin.auth.resend({ type: 'signup', email: e });\n"
    );
    expect(r.code).toBe(0);
  });

  it('prose about the pattern, in a comment', () => {
    const r = run(
      '// never call supabaseAdmin.auth.signInWithPassword — it pollutes the singleton\n' +
      '/* supabaseAnon.auth.signUp would do the same */\n' +
      'export const f = () => 1;\n'
    );
    expect(r.code).toBe(0);
  });

  it('the generated types file, which names every function', () => {
    const r = run(
      'export type Db = { signInWithPassword: never };\n',
      'types/database.types.ts'
    );
    expect(r.code).toBe(0);
  });

  it('a test file', () => {
    const r = run(
      'const supabaseAdmin = { auth: { signInWithPassword: () => {} } } as any;\n' +
      'supabaseAdmin.auth.signInWithPassword({});\n',
      'lib/subject.test.ts'
    );
    expect(r.code).toBe(0);
  });
});

describe('check-auth-client-isolation — the repo it guards', () => {
  it('passes on backend/src as it stands', () => {
    // Not a fixture: the real tree. This asserts that the compass-write fix (PR #453)
    // actually moved every session call off the shared clients.
    const r = spawnSync('node', [SCRIPT], {
      cwd: path.join(path.dirname(fileURLToPath(import.meta.url)), '..'),
      encoding: 'utf8',
    });
    expect(`${r.stdout ?? ''}${r.stderr ?? ''}`).toContain('no session-establishing GoTrue call');
    expect(r.status).toBe(0);
  });
});
