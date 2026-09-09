import { describe, it, expect } from 'vitest';
import { readFileSync, readdirSync } from 'node:fs';
import path from 'node:path';
import {
  stripCommentsAndStrings, tempTablesCreated, unsafeDropTargets,
  stripOwnTransaction, ownsItsTransaction,
} from './migration-file-guards.mjs';

// apply-migration-file.mjs exists so nobody hand-pastes a migration body into another channel.
// Its DROP guard was /DROP\s+(TABLE|SCHEMA|DATABASE)/, which refuses the house style: a
// post-verify gate takes a before-snapshot in a TEMP table and drops it at the end. Measured on
// this repo 2026-09-09, 9 of the 11 migrations containing DROP TABLE only drop their own temp
// tables. Being refused is what sends someone back to hand-pasting -- it happened in the session
// that wrote these tests.

const MIGRATIONS = path.join(__dirname, '..', '..', 'migrations');

describe('tempTablesCreated', () => {
  it('finds a plain CREATE TEMP TABLE', () => {
    expect(tempTablesCreated('CREATE TEMP TABLE _cc0083_want AS SELECT 1;')).toContain('_cc0083_want');
  });

  it('accepts TEMPORARY, GLOBAL/LOCAL and IF NOT EXISTS', () => {
    const s = `CREATE TEMPORARY TABLE a AS SELECT 1;
               CREATE GLOBAL TEMP TABLE b (x int);
               CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS c (x int);`;
    const t = tempTablesCreated(s);
    expect([...t].sort()).toEqual(['a', 'b', 'c']);
  });

  it('does not count a permanent table', () => {
    expect(tempTablesCreated('CREATE TABLE real_one (x int);').size).toBe(0);
  });
});

describe('unsafeDropTargets', () => {
  // 🔑 The shape CC_0081..CC_0084 and seven older migrations all use: drop-if-exists first so a
  //    re-run cannot trip over a leftover on a pooled connection, then create, then drop at the end.
  //    THE CREATE COMES AFTER THE FIRST DROP, which is why the scan is whole-file.
  const houseStyle = `BEGIN;
    DROP TABLE IF EXISTS _cc0083_want;
    DROP TABLE IF EXISTS _cc0083_before;
    CREATE TEMP TABLE _cc0083_want AS SELECT 1;
    CREATE TEMP TABLE _cc0083_before AS SELECT 2;
    UPDATE inform.politician_context SET sources = sources;
    DROP TABLE _cc0083_want;
    DROP TABLE _cc0083_before;
    COMMIT;`;

  it('allows the house style — temp tables the file creates itself', () => {
    expect(unsafeDropTargets(houseStyle)).toEqual([]);
  });

  it('refuses a schema-qualified table, which is never temp', () => {
    const u = unsafeDropTargets('DROP TABLE IF EXISTS app_auth.sessions;');
    expect(u).toHaveLength(1);
    expect(u[0]).toMatchObject({ kind: 'TABLE', target: 'app_auth.sessions' });
    expect(u[0].reason).toMatch(/qualified/);
  });

  it('refuses an unqualified table the file never created as TEMP', () => {
    const u = unsafeDropTargets('CREATE TEMP TABLE a AS SELECT 1; DROP TABLE b;');
    expect(u.map((x) => x.target)).toEqual(['b']);
  });

  it('refuses DROP SCHEMA and DROP DATABASE outright', () => {
    const u = unsafeDropTargets('DROP SCHEMA app_auth CASCADE; DROP DATABASE old;');
    expect(u.map((x) => x.kind)).toEqual(['SCHEMA', 'DATABASE']);
  });

  it('checks every name in a multi-table DROP, not just the first', () => {
    const u = unsafeDropTargets('CREATE TEMP TABLE a AS SELECT 1; DROP TABLE a, b CASCADE;');
    expect(u.map((x) => x.target)).toEqual(['b']);
  });

  // 🔴 Migration 1818 raises 'Aborting: app_auth.sessions still exists after DROP TABLE.' — a
  //    guard reading raw text sees a DROP TABLE there. It is prose, and prose must not decide
  //    whether a file may run.
  it('ignores a DROP mentioned inside a string literal', () => {
    const s = `CREATE TEMP TABLE t AS SELECT 1;
               DO $$ BEGIN RAISE EXCEPTION 'still there after DROP TABLE.'; END $$;
               DROP TABLE t;`;
    expect(unsafeDropTargets(s)).toEqual([]);
  });

  it('ignores a DROP mentioned in a line or block comment', () => {
    const s = `-- this file used to DROP TABLE essentials.politicians
               /* and once said DROP SCHEMA essentials */
               SELECT 1;`;
    expect(unsafeDropTargets(s)).toEqual([]);
  });

  // A DO block is where real statements live, so its contents must NOT be treated as prose.
  it('still sees a real DROP inside a dollar-quoted DO block', () => {
    const s = `DO $$ BEGIN DROP TABLE essentials.politicians; END $$;`;
    expect(unsafeDropTargets(s).map((x) => x.target)).toEqual(['essentials.politicians']);
  });

  it('is case-insensitive and survives quoted identifiers', () => {
    expect(unsafeDropTargets('create temp table Foo as select 1; drop table "Foo";')).toEqual([]);
  });
});

describe('stripOwnTransaction / ownsItsTransaction', () => {
  it('removes the outermost BEGIN; and COMMIT; so the runner owns the transaction', () => {
    const out = stripOwnTransaction('BEGIN;\nUPDATE t SET x = 1;\nCOMMIT;\n');
    expect(out).not.toMatch(/BEGIN\s*;/i);
    expect(out).not.toMatch(/COMMIT\s*;/i);
    expect(out).toMatch(/UPDATE t SET x = 1;/);
  });

  it('leaves a BEGIN inside a DO block alone', () => {
    const out = stripOwnTransaction('BEGIN;\nDO $$ BEGIN RAISE NOTICE \'hi\'; END $$;\nCOMMIT;\n');
    expect(out).toMatch(/DO \$\$ BEGIN RAISE NOTICE/);
  });

  it('recognises the house style, and a fragment that is not it', () => {
    expect(ownsItsTransaction('BEGIN;\nSELECT 1;\nCOMMIT;\n')).toBe(true);
    expect(ownsItsTransaction('SELECT 1;\n')).toBe(false);
  });
});

// 🔴 A POSITIVE CONTROL AGAINST THE REAL CORPUS. A guard that passes on hand-written fixtures and
//    refuses the actual migrations directory would be exactly the bug being fixed here, so this
//    reads the files on disk. It asserts BOTH directions: the temp-table users are allowed, and
//    the two that really drop tables in a schema are still refused.
describe('the migrations directory', () => {
  const files = readdirSync(MIGRATIONS).filter((f) => f.endsWith('.sql'));
  const withDrop = files.filter((f) => /\bDROP\s+TABLE\b/i.test(readFileSync(path.join(MIGRATIONS, f), 'utf8')));

  it('has files containing DROP TABLE at all — otherwise this suite proves nothing', () => {
    expect(withDrop.length).toBeGreaterThan(5);
  });

  it('allows every migration whose only drops are its own temp tables', () => {
    const wronglyRefused = withDrop.filter((f) => {
      const sql = readFileSync(path.join(MIGRATIONS, f), 'utf8');
      return tempTablesCreated(sql).size > 0 && unsafeDropTargets(sql).length > 0;
    });
    expect(wronglyRefused).toEqual([]);
  });

  it('still refuses the two that drop real tables in a schema', () => {
    const refused = withDrop.filter((f) => unsafeDropTargets(readFileSync(path.join(MIGRATIONS, f), 'utf8')).length > 0);
    expect(refused.sort()).toEqual([
      '1818_retire_app_auth_credentials.sql',
      '1819_drop_app_auth_schema.sql',
    ]);
  });
});
