/**
 * Architecture test: the Bloomington council-record migrations.
 * Static checks on the SQL text: RLS, grants, idempotence, and that the exception-cause CHECK list
 * is exactly EXCEPTION_CAUSES in the code.
 */
import { describe, it, expect } from 'vitest';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';
import { EXCEPTION_CAUSES } from '../../backend/src/lib/localRecord/types.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const MIG = path.resolve(__dirname, '../../backend/migrations');

function read(name: string): string {
  return fs.readFileSync(path.join(MIG, name), 'utf8');
}
/** Drop `--` comment lines so prose cannot satisfy or trip a check. */
function code(name: string): string {
  return read(name).split('\n').filter((l) => !/^\s*--/.test(l)).join('\n');
}

const DOCS = 'CA_PENDING_local_record_source_documents.sql';
const ROLLS = 'CA_PENDING_local_record_roll_calls.sql';
const EXC = 'CA_PENDING_local_record_exceptions.sql';
const VOTES = 'CA_PENDING_local_record_votes_columns.sql';
const IDX = 'CA_PENDING_local_record_votes_roll_call_index.sql';
const ALL = [DOCS, ROLLS, EXC, VOTES, IDX];

describe('council-record migrations', () => {
  it('all five files exist', () => {
    for (const f of ALL) expect(fs.existsSync(path.join(MIG, f)), f).toBe(true);
  });

  it('no file uses a bulk grant', () => {
    for (const f of ALL) expect(code(f), f).not.toMatch(/grant\s+.*\s+on\s+all\s+tables/i);
  });

  it.each([
    [DOCS, 'local_record_source_documents'],
    [ROLLS, 'legislative_roll_calls'],
    [EXC, 'local_record_exceptions'],
  ])('%s creates its table idempotently and enables RLS in the same file', (f, table) => {
    const c = code(f);
    expect(c).toMatch(new RegExp(`create table if not exists essentials\\.${table}\\b`, 'i'));
    expect(c).toMatch(new RegExp(`alter table essentials\\.${table}\\s+enable row level security`, 'i'));
    expect(c).toMatch(new RegExp(`grant all on essentials\\.${table} to service_role`, 'i'));
  });

  it.each([
    [DOCS, 'local_record_source_documents'],
    [EXC, 'local_record_exceptions'],
  ])('%s is private: no grant or policy for anon or authenticated, and they are revoked', (f, table) => {
    const c = code(f);
    expect(c).not.toMatch(/grant[^;]*\bto\b[^;]*\b(anon|authenticated)\b/i);
    expect(c).not.toMatch(/create policy[^;]*\bto\b[^;]*\b(anon|authenticated)\b/i);
    expect(c).toMatch(new RegExp(`revoke all on essentials\\.${table} from anon, authenticated`, 'i'));
  });

  it('roll calls are public read only', () => {
    const c = code(ROLLS);
    expect(c).toMatch(/grant select on essentials\.legislative_roll_calls to anon, authenticated/i);
    expect(c).toMatch(/revoke (insert, update, delete|all)[^;]*on essentials\.legislative_roll_calls from anon, authenticated/i);
    expect(c).toMatch(/create policy "public read"\s+on essentials\.legislative_roll_calls\s+for select/i);
    expect(c).not.toMatch(/grant (?!select)[^;]*to[^;]*(anon|authenticated)/i);
  });

  it('roll calls reference source documents (so the documents file applies first)', () => {
    expect(code(ROLLS)).toMatch(/references essentials\.local_record_source_documents\(id\)/i);
  });

  it('source_documents kind is memorandum, minutes or item_text; unique on url + sha256', () => {
    const c = code(DOCS);
    expect(c).toMatch(/check \(kind in \('memorandum', ?'minutes', ?'item_text'\)\)/i);
    expect(c).toMatch(/unique \(source_url, sha256\)/i);
  });

  it('roll_calls has the unique key the writer upserts on', () => {
    expect(code(ROLLS)).toMatch(/unique \(city_scope, external_vote_id\)/i);
  });

  it('exceptions cause CHECK list equals EXCEPTION_CAUSES exactly', () => {
    const m = code(EXC).match(/check \(cause in \(([^)]*)\)\)/i);
    expect(m, 'cause CHECK present').not.toBeNull();
    const listed = [...m![1].matchAll(/'([^']+)'/g)].map((x) => x[1]);
    expect([...listed].sort()).toEqual([...EXCEPTION_CAUSES].sort());
    expect(new Set(listed).size).toBe(listed.length);
  });

  it('exceptions has opened_at (not null, default now()), updated_at and the upsert key', () => {
    const c = code(EXC);
    expect(c).toMatch(/opened_at\s+timestamptz\s+not null\s+default now\(\)/i);
    expect(c).toMatch(/updated_at\s+timestamptz\s+default now\(\)/i);
    expect(c).toMatch(/unique \(city_scope, cause, subject\)/i);
  });

  it('votes columns: ADD COLUMN IF NOT EXISTS, nullable, no DEFAULT', () => {
    const c = code(VOTES);
    for (const col of ['roll_call_id', 'name_as_printed', 'worked_out', 'confirmed_from']) {
      expect(c, col).toMatch(new RegExp(`add column if not exists ${col}\\b`, 'i'));
    }
    expect(c).not.toMatch(/\bdefault\b/i);
    expect(c).not.toMatch(/not null/i);
    expect(c).toMatch(/references essentials\.legislative_roll_calls\(id\)/i);
    expect(c).toMatch(/references essentials\.local_record_source_documents\(id\)/i);
  });

  it('roll_call_id index is concurrent, idempotent and outside any transaction', () => {
    const c = code(IDX);
    expect(c).toMatch(/create index concurrently if not exists \S+\s+on essentials\.legislative_votes \(roll_call_id\)/i);
    expect(c).not.toMatch(/^\s*(begin|commit|start transaction)\s*;/im); // the DO $$ BEGIN block is fine
  });
});
