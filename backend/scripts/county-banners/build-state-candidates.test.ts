import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { buildStateCandidates, STATE_FIPS } from './build-state-candidates.js';
import type { CandidateFile } from './types.js';
import type { QueryFn } from './locate.js';

let dir: string;
beforeEach(() => { dir = fs.mkdtempSync(path.join(os.tmpdir(), 'cb-state-')); });
afterEach(() => { fs.rmSync(dir, { recursive: true, force: true }); });

const NE = Array.from({ length: 93 }, (_, i) => ({ geo_id: `31${String(i * 2 + 1).padStart(3, '0')}`, name: `County ${i}` }));
const good = (title: string): CandidateFile => ({
  title, url: 'u', width: 3000, height: 2000, licence: 'CC BY 4.0', author: 'A', date: null,
  sourceCategory: 'c', lat: 40.8, lon: -99.7,
});

function deps(over: Partial<Parameters<typeof buildStateCandidates>[2]> = {}) {
  const query: QueryFn = async (sql) => (/ST_Contains/i.test(sql) ? [] : NE);
  return {
    query,
    sweep: async () => [] as CandidateFile[],
    attach: async (f: CandidateFile[]) => f,
    assign: async () => ({ located: new Map<string, CandidateFile[]>(), unlocated: [], outside: [] }),
    ...over,
  };
}

describe('STATE_FIPS', () => {
  it('maps USPS to the FIPS the boundary table uses', () => { expect(STATE_FIPS.NE).toBe('31'); });
  it('covers all 50 states plus DC', () => { expect(Object.keys(STATE_FIPS).length).toBeGreaterThanOrEqual(51); });
});

describe('buildStateCandidates', () => {
  it('emits a row for every county in the state, including those with no candidates', async () => {
    const rows = await buildStateCandidates('NE', dir, deps());
    expect(rows).toHaveLength(93);
    expect(rows.every((r) => r.swept)).toBe(true);
  });

  it('marks a county whose sweep threw as swept:false, distinct from zero candidates', async () => {
    // Review Focus 5: a crashed run must never read as genuine absence.
    let n = 0;
    const rows = await buildStateCandidates('NE', dir, deps({
      sweep: async () => { if (++n === 1) throw new Error('boom'); return []; },
    }));
    expect(rows[0].swept).toBe(false);
    expect(rows[0].candidates).toEqual([]);
    expect(rows[1].swept).toBe(true);
    expect(rows.filter((r) => !r.swept)).toHaveLength(1);
  });

  it('caps candidates at five per county and keeps the rest retrievable', async () => {
    const twelve = Array.from({ length: 12 }, (_, i) => good(`f${i}.jpg`));
    const rows = await buildStateCandidates('NE', dir, deps({
      sweep: async () => twelve,
      assign: async () => ({ located: new Map([[NE[0].geo_id, twelve]]), unlocated: [], outside: [] }),
    }));
    const r = rows.find((x) => x.geoid === NE[0].geo_id)!;
    expect(r.candidates).toHaveLength(5);
    const all = JSON.parse(fs.readFileSync(path.join(dir, `${NE[0].geo_id}.json`), 'utf8'));
    expect(all.allCandidates).toHaveLength(12);
  });

  it('carries the rejection counts onto the county row', async () => {
    const small = [{ ...good('tiny.jpg'), width: 100, height: 100 }];
    const rows = await buildStateCandidates('NE', dir, deps({
      sweep: async () => small,
      assign: async () => ({ located: new Map([[NE[0].geo_id, small]]), unlocated: [], outside: [] }),
    }));
    expect(rows.find((x) => x.geoid === NE[0].geo_id)!.rejected.too_small).toBe(1);
  });

  it('is resumable — a second run does not re-sweep a county already written', async () => {
    let sweeps = 0;
    const d = deps({ sweep: async () => { sweeps++; return []; } });
    await buildStateCandidates('NE', dir, d);
    const first = sweeps;
    await buildStateCandidates('NE', dir, d);
    expect(sweeps).toBe(first);
  });

  it('re-sweeps a county left swept:false by an earlier crashed run', async () => {
    let n = 0;
    const d = deps({ sweep: async () => { if (++n === 1) throw new Error('boom'); return []; } });
    await buildStateCandidates('NE', dir, d);
    const before = n;
    await buildStateCandidates('NE', dir, d);
    expect(n).toBe(before + 1);   // exactly the one that failed, not all 93
  });

  it('rejects an unknown state code rather than querying with undefined', async () => {
    await expect(buildStateCandidates('ZZ', dir, deps())).rejects.toThrow(/ZZ/);
  });
});
