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
const VALIDATE = 'CA_PENDING_local_record_votes_validate_fks.sql';
const BUCKET = 'CA_PENDING_local_record_storage_bucket.sql';
const ALL = [DOCS, ROLLS, EXC, VOTES, IDX, VALIDATE, BUCKET];

describe('council-record migrations', () => {
  it('all seven files exist', () => {
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
    expect(c).toMatch(new RegExp(`revoke all on essentials\\.${table} from public, anon, authenticated`, 'i'));
  });

  it('roll calls are public read only', () => {
    const c = code(ROLLS);
    expect(c).toMatch(/grant select on essentials\.legislative_roll_calls to anon, authenticated/i);
    expect(c).toMatch(/revoke (insert, update, delete|all)[^;]*on essentials\.legislative_roll_calls from public, anon, authenticated/i);
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
    // No FK validation scan under ACCESS EXCLUSIVE: every REFERENCES is a NOT VALID constraint add.
    const withRef = c.split(';').filter((st) => /\breferences\b/i.test(st));
    expect(withRef.length).toBe(2);
    for (const st of withRef) {
      expect(st).toMatch(/add constraint/i);
      expect(st).toMatch(/not valid/i);
    }
    expect(c).toMatch(/pg_constraint/i); // guarded, so the file is idempotent
  });

  it('validate file validates both FKs, outside the columns file', () => {
    const c = code(VALIDATE);
    expect((c.match(/validate constraint/gi) ?? []).length).toBe(2);
    expect(c).not.toMatch(/add column|add constraint/i);
  });

  it('roll_call_id index is concurrent, idempotent and outside any transaction', () => {
    const c = code(IDX);
    expect(c).toMatch(/create index concurrently if not exists \S+\s+on essentials\.legislative_votes \(roll_call_id\)/i);
    expect(c).not.toMatch(/^\s*(begin|commit|start transaction)\s*;/im); // the DO $$ BEGIN block is fine
  });

  it('the storage bucket local-record-sources is created private and idempotently, with a gate that it is not public', () => {
    const c = code(BUCKET);
    expect(c).toMatch(/insert into storage\.buckets \(id, name, public[^)]*\)\s*values \('local-record-sources', 'local-record-sources', false/i);
    expect(c).toMatch(/on conflict \(id\) do nothing/i);
    expect(c).toMatch(/if b\.public then raise exception/i);
    expect(c).toMatch(/if not found then raise exception/i);
    expect(c).not.toMatch(/create policy/i);
    // Only the content types store.ts uploads.
    expect(c).toMatch(/array\['application\/pdf', 'text\/plain'\]/);
    expect(c).toMatch(/^begin;/im);
    expect(c).toMatch(/^commit;/im);
  });

  it('the code writes to the bucket the migration creates', () => {
    const src = fs.readFileSync(path.resolve(__dirname, '../../backend/src/lib/localRecord/refresh.ts'), 'utf8');
    expect(src).toMatch(/const BUCKET = 'local-record-sources'/);
  });
});

const PEOPLE = 'CA_PENDING_bloomington_council_people_and_terms.sql';
const MERGE = 'CA_PENDING_bloomington_district5_office_merge.sql';

describe('Bloomington people-and-terms file', () => {
  it('selects council seats by chamber slug AND position name (the City Clerk is not a seat)', () => {
    const c = code(PEOPLE);
    const sels = c.match(/ch\.slug = 'bloomington-common-council'[^;]*/g) ?? [];
    expect(sels.length).toBeGreaterThanOrEqual(2);
    for (const s of sels) expect(s).toMatch(/normalized_position_name = 'City Legislature'/);
  });

  it('only a day-precision start counts as a conflict; a coarser one may be replaced (Daily)', () => {
    const c = code(PEOPLE);
    expect(c).toMatch(/ot\.term_start <> pl\.term_start\s+AND ot\.start_precision = 'day'/);
    expect(c).toMatch(/\(ot\.term_start IS NULL OR ot\.start_precision <> 'day'\)/);
    expect(c).toMatch(/start was '\s*\|\| coalesce\(ot\.term_start::text, 'NULL'\) \|\| ', precision ''' \|\| ot\.start_precision/);
    // The old precision is stated once in that source text, not twice.
    expect(c).not.toMatch(/start_precision was '''\s*\|\|\s*ot\.start_precision \|\| ''' \(was/);
  });
});

describe('Bloomington District 5 office merge', () => {
  const c = () => code(MERGE);
  it('exists, is one transaction, and runs before the people-and-terms file (it is named so)', () => {
    expect(fs.existsSync(path.join(MIG, MERGE))).toBe(true);
    expect(c()).toMatch(/^\s*BEGIN;/m);
    expect(c()).toMatch(/^\s*COMMIT;/m);
    expect(read(MERGE)).toMatch(/BEFORE .*people_and_terms|before .*people_and_terms/);
  });
  it('moves the term and repoints the snapshot before deleting the retired office', () => {
    const s = c();
    const move = s.search(/UPDATE essentials\.office_terms/i);
    const repoint = s.search(/UPDATE essentials\.politicians/i);
    const del = s.search(/DELETE FROM essentials\.offices/i);
    expect(move).toBeGreaterThan(-1);
    expect(repoint).toBeGreaterThan(move);
    expect(del).toBeGreaterThan(repoint);
  });
  it('names both offices and the district exactly, and never sets is_vacant', () => {
    const s = c();
    for (const id of ['48d59066-51aa-4fca-9e92-edecfaeb4388', 'c59ebfa0-e6a2-4e9c-ba1c-db97f79c58d1', 'cd647e3c-e2d6-40a0-b8db-b9dfbe6f597d'])
      expect(s).toContain(id);
    expect(s).not.toMatch(/SET[^;]*is_vacant/i);
  });
  it('post-verify never gates a total term count on KEEP (the people file later adds a third term there)', () => {
    const post = c().slice(c().lastIndexOf('DO $$'));
    expect(post).not.toMatch(/count\(\*\) INTO v_n FROM essentials\.office_terms WHERE office_id = v_keep;/);
    expect(post).not.toMatch(/expected exactly 2 terms/);
    expect(post).toMatch(/office_id = v_keep AND politician_id = v_rana/);
    expect(post).toMatch(/office_id = v_keep AND politician_id = v_daily/);
  });
  it('creates no table or view, so it owes no RLS or grants', () => {
    expect(c()).not.toMatch(/create\s+(table|view)/i);
  });
});
