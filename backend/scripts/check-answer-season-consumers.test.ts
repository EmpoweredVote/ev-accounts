import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// Integration tests, same shape as check-migration-numbers.test.ts: build a real
// src/ tree in a temp dir and run the script as a subprocess, exactly as CI does.
//
// The thing worth testing is that the gate DISCRIMINATES. A gate that fails on
// everything is as useless as one that passes everything, and the failure mode
// that matters here is the false green — a consumer that keeps the bare
// (politician_id, topic_id) pair while the gate reports OK. Every case below
// pins one direction of that decision.
//
// DATABASE_URL is stripped from the child env so these exercise the static half
// only, deterministically and without a database.

const SCRIPT = path.join(path.dirname(fileURLToPath(import.meta.url)), 'check-answer-season-consumers.mjs');

let root: string;
beforeAll(() => { root = mkdtempSync(path.join(tmpdir(), 'seasongate-')); });
afterAll(() => { rmSync(root, { recursive: true, force: true }); });

let n = 0;
/** Write a one-file src/ tree in a fresh dir and run the gate against it. */
function run(contents: string): { code: number; out: string } {
  const dir = path.join(root, `case-${++n}`);
  mkdirSync(path.join(dir, 'src', 'lib'), { recursive: true });
  writeFileSync(path.join(dir, 'src', 'lib', 'subject.ts'), contents, 'utf8');
  const env = { ...process.env };
  delete env.DATABASE_URL;
  // spawnSync, not execFileSync: on a zero exit execFileSync hands back stdout
  // only, which silently drops the stderr-borne SKIP notice the last test asserts on.
  const r = spawnSync('node', [SCRIPT], { cwd: dir, encoding: 'utf8', env });
  return { code: r.status ?? -1, out: `${r.stdout ?? ''}${r.stderr ?? ''}` };
}

const q = (sql: string) => `import { pool } from './db.js';\nexport const f = () => pool.query(\`${sql}\`);\n`;

describe('check-answer-season-consumers — it must fail', () => {
  it('a SELECT on the answer tables with no season', () => {
    const r = run(q('SELECT value FROM inform.politician_answers WHERE politician_id = $1'));
    expect(r.code).toBe(1);
    expect(r.out).toContain('without naming a season');
  });

  it('an ON CONFLICT on the bare pair — this is the 42P10 break', () => {
    const r = run(q(
      'INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ($1,$2,$3) ' +
      'ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value'));
    expect(r.code).toBe(1);
    expect(r.out).toContain('42P10');
  });

  // The reason the unit of matching is the literal and not the file. Seasoning
  // one query must not clear the others sharing its file.
  it('a seasoned query does not excuse an unseasoned one in the same file', () => {
    const r = run(
      q('SELECT value FROM inform.politician_answers WHERE politician_id = $1 AND season_id = $2') +
      q('SELECT value FROM inform.politician_context WHERE politician_id = $1'));
    expect(r.code).toBe(1);
    expect(r.out).toMatch(/1 SQL literal\(s\)/);
  });

  // Mentioning a season does not make a stale upsert target safe: ON CONFLICT
  // needs a unique index on exactly the columns it names.
  it('an ON CONFLICT on the bare pair, in a literal that does mention season_id', () => {
    const r = run(q(
      'INSERT INTO inform.politician_answers (politician_id, topic_id, value, season_id) ' +
      'VALUES ($1,$2,$3,$4) ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value'));
    expect(r.code).toBe(1);
    expect(r.out).toContain('42P10');
  });

  it('an aliased ON CONFLICT on the bare pair', () => {
    const r = run(q(
      'INSERT INTO inform.politician_answers AS pa (politician_id, topic_id) VALUES ($1,$2) ' +
      'ON CONFLICT (pa.politician_id, pa.topic_id) DO NOTHING'));
    expect(r.code).toBe(1);
  });

  it('an unqualified FROM, with no inform. prefix', () => {
    const r = run(q('SELECT value FROM politician_answers WHERE politician_id = $1'));
    expect(r.code).toBe(1);
  });
});

describe('check-answer-season-consumers — it must pass', () => {
  it('a seasoned SELECT', () => {
    const r = run(q('SELECT value FROM inform.politician_answers WHERE politician_id = $1 AND season_id = $2'));
    expect(r.code).toBe(0);
    expect(r.out).toContain('answer-season consumers OK');
  });

  it('a season-aware ON CONFLICT', () => {
    const r = run(q(
      'INSERT INTO inform.politician_answers (politician_id, topic_id, season_id, value) VALUES ($1,$2,$3,$4) ' +
      'ON CONFLICT (politician_id, topic_id, season_id) DO UPDATE SET value = EXCLUDED.value'));
    expect(r.code).toBe(0);
  });

  it('a query joining season_questions instead of naming season_id', () => {
    const r = run(q(
      'SELECT a.value FROM inform.politician_answers a ' +
      'JOIN inform.season_questions sq ON sq.topic_id = a.topic_id'));
    expect(r.code).toBe(0);
  });

  // These two are the false positives that an earlier draft of the gate
  // reported. Neither queries the table: one is an audit-log action name, the
  // other an RPC name. Both merely CONTAIN the table name as a substring.
  it('an audit-log action name that contains the table name', () => {
    const r = run(`export const f = () => logAdminAction(actor, 'update_politician_answers', null, {});\n`);
    expect(r.code).toBe(0);
  });

  it('an RPC name that contains the table name', () => {
    const r = run(`export const f = () => adminRpc('admin_update_politician_answers', {});\n`);
    expect(r.code).toBe(0);
  });

  it('prose about the tables in a comment', () => {
    const r = run(
      '// falls back to politician_answers (Path B)\n' +
      '/* SELECT value FROM inform.politician_answers */\n' +
      'export const f = () => 1;\n');
    expect(r.code).toBe(0);
  });

  it('SQL against an unrelated table', () => {
    const r = run(q('SELECT id FROM essentials.politicians WHERE id = $1'));
    expect(r.code).toBe(0);
  });
});

// The escape hatch, modelled on CLAUDE.md's `-- @context-decision:` line. Some
// questions really are about every season ("has this person EVER been
// researched"), and narrowing those would make the query wrong to make the gate
// quiet. But it must be a stated decision, never a silent pass.
describe('check-answer-season-consumers — @season-scope: all-seasons', () => {
  const REASON = 'coverage is "ever researched", and DISTINCT politician_id collapses the per-season rows';

  it('accepts a declared cross-season READ with a reason', () => {
    const r = run(q(
      `SELECT 1 FROM (SELECT DISTINCT politician_id FROM inform.politician_answers) ans\n` +
      `     -- @season-scope: all-seasons — ${REASON}`));
    expect(r.code).toBe(0);
  });

  it('refuses a bare marker with no stated reason', () => {
    const r = run(q(
      'SELECT 1 FROM inform.politician_answers\n' +
      '     -- @season-scope: all-seasons'));
    expect(r.code).toBe(1);
    expect(r.out).toContain('no stated reason');
  });

  it('refuses a hand-wave too short to be a reason', () => {
    const r = run(q(
      'SELECT 1 FROM inform.politician_answers\n' +
      '     -- @season-scope: all-seasons — needed'));
    expect(r.code).toBe(1);
    expect(r.out).toContain('no stated reason');
  });

  // The hatch is for judgement calls about reads. A cross-season write is a bug,
  // and no comment makes ON CONFLICT match an index that is not there.
  it('refuses the marker on an UPDATE', () => {
    const r = run(q(
      `UPDATE inform.politician_context SET reasoning = $1 WHERE politician_id = $2\n` +
      `     -- @season-scope: all-seasons — ${REASON}`));
    expect(r.code).toBe(1);
    expect(r.out).toContain('on a WRITE');
  });

  it('refuses the marker on a DELETE', () => {
    const r = run(q(
      `DELETE FROM inform.politician_answers WHERE politician_id = $1\n` +
      `     -- @season-scope: all-seasons — ${REASON}`));
    expect(r.code).toBe(1);
    expect(r.out).toContain('on a WRITE');
  });

  it('refuses the marker on a stale ON CONFLICT, ahead of every other check', () => {
    const r = run(q(
      `INSERT INTO inform.politician_answers (politician_id, topic_id) VALUES ($1,$2) ` +
      `ON CONFLICT (politician_id, topic_id) DO NOTHING\n` +
      `     -- @season-scope: all-seasons — ${REASON}`));
    expect(r.code).toBe(1);
    expect(r.out).toContain('42P10');
  });

  // An escape hatch nobody can see is an escape hatch nobody reviews.
  it('reports every declared exemption even on a green run', () => {
    const r = run(q(
      `SELECT 1 FROM (SELECT DISTINCT politician_id FROM inform.politician_answers) ans\n` +
      `     -- @season-scope: all-seasons — ${REASON}`));
    expect(r.code).toBe(0);
    expect(r.out).toContain('declare @season-scope: all-seasons');
    expect(r.out).toMatch(/subject\.ts:\d+/);
  });
});

describe('check-answer-season-consumers — the skipped RPC half is visible', () => {
  it('says plainly that the database side went unchecked', () => {
    const r = run(q('SELECT value FROM inform.politician_answers WHERE politician_id = $1 AND season_id = $2'));
    expect(r.code).toBe(0);
    // A silent skip reads as coverage. It must not.
    expect(r.out).toContain('SKIP: DATABASE_URL not set');
    expect(r.out).toContain('the RPC half was skipped');
  });
});
