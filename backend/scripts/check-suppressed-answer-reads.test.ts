import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// Same shape as check-answer-season-consumers.test.ts: build a real src/ tree in
// a temp dir and run the script as a subprocess, exactly as CI does.
//
// The thing worth testing is that the gate DISCRIMINATES, and the failure mode
// that matters is the false green — a read of compass_responses_current that
// ships unflagged and shows somebody a stance on a rung they never chose. Every
// case below pins one direction of that decision.

const SCRIPT = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  'check-suppressed-answer-reads.mjs'
);

let root: string;
beforeAll(() => { root = mkdtempSync(path.join(tmpdir(), 'suppressgate-')); });
afterAll(() => { rmSync(root, { recursive: true, force: true }); });

let n = 0;
/** Write a one-file src/ tree in a fresh dir and run the gate against it. */
function run(contents: string, file = 'lib/subject.ts'): { code: number; out: string } {
  const dir = path.join(root, `case-${++n}`);
  const target = path.join(dir, 'src', file);
  mkdirSync(path.dirname(target), { recursive: true });
  writeFileSync(target, contents, 'utf8');
  const r = spawnSync('node', [SCRIPT], { cwd: dir, encoding: 'utf8' });
  return { code: r.status ?? -1, out: `${r.stdout ?? ''}${r.stderr ?? ''}` };
}

const sql = (body: string) =>
  `import { pool } from './db.js';\nexport const f = () => pool.query(\`${body}\`);\n`;

const builder = (table: string) =>
  `import { supabaseAdmin } from './db.js';\n` +
  `export const f = () => supabaseAdmin.schema('inform').from('${table}').select('value');\n`;

describe('check-suppressed-answer-reads — it must fail', () => {
  it('a SQL read of compass_responses_current', () => {
    const r = run(sql('SELECT value FROM inform.compass_responses_current WHERE user_id = $1'));
    expect(r.code).toBe(1);
    expect(r.out).toContain('compass_responses_effective');
  });

  it('a PostgREST builder read of compass_responses_current', () => {
    // 🔴 The case that motivated the gate having a builder half at all. Six of
    // the eleven original reads were builder calls, and a builder call names the
    // view inside a quoted argument with no clause keyword — SQL matching alone
    // reports "all clear" while half the reads are unsuppressed.
    const r = run(builder('compass_responses_current'));
    expect(r.code).toBe(1);
    expect(r.out).toContain('compass_responses_effective');
  });

  it('reports the line, so the reader can jump to it', () => {
    const r = run(sql('SELECT value FROM inform.compass_responses_current WHERE user_id = $1'));
    expect(r.out).toMatch(/lib\/subject\.ts:\d+/);
  });

  // The unit of matching is the read, not the file. Fixing one must not clear
  // the others sharing its file.
  it('a fixed read does not excuse an unfixed one in the same file', () => {
    const r = run(
      'import { pool } from \'./db.js\';\n' +
      'export const good = () => pool.query(`SELECT value FROM inform.compass_responses_effective WHERE user_id = $1`);\n' +
      'export const bad  = () => pool.query(`SELECT value FROM inform.compass_responses_current WHERE user_id = $1`);\n'
    );
    expect(r.code).toBe(1);
    expect(r.out).toContain('1 site(s)');
  });

  it('a bare escape marker with no reason', () => {
    const r = run(sql(
      '-- @suppression-scope: all-answers\n' +
      'SELECT value FROM inform.compass_responses_current WHERE user_id = $1'));
    expect(r.code).toBe(1);
    expect(r.out).toMatch(/reason/i);
  });

  it('an escape marker whose reason is too short to be one', () => {
    const r = run(sql(
      '-- @suppression-scope: all-answers — because\n' +
      'SELECT value FROM inform.compass_responses_current WHERE user_id = $1'));
    expect(r.code).toBe(1);
    expect(r.out).toMatch(/reason/i);
  });
});

describe('check-suppressed-answer-reads — it must pass', () => {
  it('a read of the effective view', () => {
    const r = run(sql('SELECT value FROM inform.compass_responses_effective WHERE user_id = $1'));
    expect(r.code).toBe(0);
  });

  it('a builder read of the effective view', () => {
    const r = run(builder('compass_responses_effective'));
    expect(r.code).toBe(0);
  });

  it('a write to the base table — writes are not reads', () => {
    // Saving an answer must still write compass_responses. The gate is about
    // what is shown back, and suppressing on write would destroy the value
    // rather than withhold it.
    const r = run(sql(
      'INSERT INTO inform.compass_responses (user_id, topic_id, value) VALUES ($1,$2,$3)'));
    expect(r.code).toBe(0);
  });

  it('prose about the view, in a comment', () => {
    // The gate reads code, not commentary. Several files explain the collapse in
    // comments that name compass_responses_current on purpose.
    const r = run(
      '// compass_responses_current collapses to the newest season per topic.\n' +
      '/* and inform.compass_responses_current is where that happens */\n' +
      'export const f = () => 1;\n'
    );
    expect(r.code).toBe(0);
  });

  it('the generated types file, which names every view', () => {
    const r = run(
      'export type Db = { compass_responses_current: { Row: { value: number } } };\n',
      'types/database.types.ts'
    );
    expect(r.code).toBe(0);
  });

  it('a test file', () => {
    const r = run(sql('SELECT value FROM inform.compass_responses_current'), 'lib/subject.test.ts');
    expect(r.code).toBe(0);
  });

  it('an escape marker carrying a real reason', () => {
    const r = run(sql(
      '-- @suppression-scope: all-answers — the admin export is a record of what\n' +
      '--   the user actually stored, and suppressing it would hide the very rows\n' +
      '--   the re-ask needs to show them.\n' +
      'SELECT value FROM inform.compass_responses_current WHERE user_id = $1'));
    expect(r.code).toBe(0);
    expect(r.out).toMatch(/declared/i);
  });
});

describe('check-suppressed-answer-reads — the repo it guards', () => {
  it('passes on backend/src as it stands', () => {
    // Not a fixture: the real tree. This is the assertion that all eleven reads
    // were actually switched, for the six files that have no test file of their own.
    const r = spawnSync('node', [SCRIPT], {
      cwd: path.join(path.dirname(fileURLToPath(import.meta.url)), '..'),
      encoding: 'utf8',
    });
    expect(`${r.stdout ?? ''}${r.stderr ?? ''}`).toContain('read the effective view');
    expect(r.status).toBe(0);
  });
});
