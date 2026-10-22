import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { importFindFile, nextBatch, parseUnit } from './stage5Find.js';
import { findingId, upsertFindings } from './sourceStore.js';
import type { RosterRow } from './stage5Roster.js';

const id = (n: number) => `${String(n).padStart(8, '0')}-0000-4000-8000-000000000000`;
const row = (n: number, over: Partial<RosterRow> = {}): RosterRow => ({
  politician_id: id(n), full_name: `Person ${n}`, office_id: `o${n}`, level: 'state', state: 'IN',
  scope: 'sitting', leaving: 'no', race_ids: [], ...over,
});
const prov = { fetched_by: 't', fetched_at: '2026-10-22T00:00:00Z', method: 'webfetch' as const };

let store: string;
beforeEach(() => { store = mkdtempSync(join(tmpdir(), 'stage5-find-')); });
afterEach(() => { rmSync(store, { recursive: true, force: true }); });

const searched = (n: number, topic = 'voting-rights', season = 3) => upsertFindings(store, {
  politician_id: id(n), findings: [],
  searches: [{ topic_key: topic, season, subjects: ['voter ID'], places: ['site'], found: 0, at: '2026-10-22T00:00:00Z', by: 't' }],
});
const prefilled = (n: number) => {
  const f = { kind: 'record' as const, url: 'https://x.example/b', date: '2011-04-12', date_precision: 'day' as const, instrument_id: 'IN-SB-483-2011',
    act: 'yea' as const, motion: 'final passage', note: 'n', subjects: ['voter ID at the polls'], topic_keys: ['voting-rights'], provenance: prov };
  upsertFindings(store, { politician_id: id(n), findings: [{ id: findingId(f), ...f }], searches: [] });
};

describe('nextBatch', () => {
  it('skips a person already searched for this topic and season, and keeps one searched for another', () => {
    searched(1);
    searched(2, 'abortion');
    searched(3, 'voting-rights', 2);
    const b = nextBatch([row(1), row(2), row(3)], store, 'voting-rights', 3, { level: 'state', state: 'IN' }, 10);
    expect(b.map((r) => r.politician_id)).toEqual([id(2), id(3)]);
  });

  it('puts people with pre-filled findings first', () => {
    prefilled(3);
    const b = nextBatch([row(1), row(2), row(3)], store, 'voting-rights', 3, { level: 'state', state: 'IN' }, 10);
    expect(b[0].politician_id).toBe(id(3));
  });

  it('leaves out officials who are leaving, and people outside the unit', () => {
    const b = nextBatch(
      [row(1, { leaving: 'yes' }), row(2, { state: 'NC' }), row(3, { level: 'federal' }), row(4)],
      store, 'voting-rights', 3, { level: 'state', state: 'IN' }, 10,
    );
    expect(b.map((r) => r.politician_id)).toEqual([id(4)]);
  });

  it('takes the federal unit across states, and stops at the batch size', () => {
    const b = nextBatch([row(1, { level: 'federal', state: 'IN' }), row(2, { level: 'federal', state: 'NC' }), row(3, { level: 'federal' })],
      store, 'voting-rights', 3, { level: 'federal' }, 2);
    expect(b).toHaveLength(2);
  });
});

describe('parseUnit', () => {
  it('reads federal, state:xx and local:xx', () => {
    expect(parseUnit('federal')).toEqual({ level: 'federal' });
    expect(parseUnit('state:in')).toEqual({ level: 'state', state: 'IN' });
    expect(parseUnit('local:nc')).toEqual({ level: 'local', state: 'NC' });
    expect(() => parseUnit('state')).toThrow(/unit/);
  });
});

describe('importFindFile', () => {
  const file = (over: Record<string, unknown> = {}) => ({
    politician_id: id(1),
    searched: { subjects: ['voter ID at the polls'], places: ['campaign site', 'On the Record'] },
    findings: [{
      kind: 'own-words', url: 'https://x.example/forum', date: '2026-09-01', date_precision: 'day',
      passage: 'Every voter should show ID.', note: 'Backs ID at the polls.', subjects: ['voter ID at the polls'],
    }],
    ...over,
  });

  it('writes one search entry and the findings with ids and provenance', () => {
    const pf = importFindFile(file(), 'voting-rights', 3, { by: 'collector-7', at: '2026-10-22T01:00:00Z' });
    expect(pf.searches).toEqual([expect.objectContaining({ topic_key: 'voting-rights', season: 3, found: 1, by: 'collector-7' })]);
    expect(pf.findings[0]).toMatchObject({ topic_keys: ['voting-rights'], provenance: { fetched_by: 'collector-7', method: 'webfetch' } });
    expect(pf.findings[0].id).toMatch(/^[0-9a-f]{64}$/);
  });

  it('still writes a search entry when nothing was found', () => {
    const pf = importFindFile(file({ findings: [] }), 'voting-rights', 3, { by: 'c', at: '2026-10-22T01:00:00Z' });
    expect(pf.findings).toEqual([]);
    expect(pf.searches[0].found).toBe(0);
  });

  it('refuses a finding with no subjects, naming the person', () => {
    const bad = file({ findings: [{ ...file().findings[0], subjects: [] }] });
    expect(() => importFindFile(bad, 'voting-rights', 3, { by: 'c', at: 'x' })).toThrow(new RegExp(id(1)));
  });

  it('refuses a file that carries a rung or value (the searcher does not code)', () => {
    const bad = file({ findings: [{ ...file().findings[0], value: 4 }] });
    expect(() => importFindFile(bad, 'voting-rights', 3, { by: 'c', at: 'x' })).toThrow(/value/);
  });
});
