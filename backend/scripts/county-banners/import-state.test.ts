import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { importState, descriptionPageUrl } from './import-state.js';
import type { CandidateFile } from './types.js';

function candidate(over: Partial<CandidateFile> = {}): CandidateFile {
  return {
    title: 'File:Kent County Courthouse.jpg',
    url: 'https://upload.wikimedia.org/wikipedia/commons/a/ab/Kent.jpg',
    width: 3000,
    height: 2000,
    licence: 'cc_by-sa_4.0',
    author: 'A Photographer',
    date: null,
    sourceCategory: 'Category:Kent County, Delaware',
    lat: 39.1,
    lon: -75.5,
    ...over,
  } as CandidateFile;
}

function countyRow(over: Record<string, unknown> = {}) {
  return {
    geoid: '10001',
    name: 'Kent County',
    swept: true,
    candidates: [candidate()],
    rejected: { too_small: 2 },
    allCandidates: [candidate()],
    filesSwept: 77,
    categoriesFound: 4,
    categoryErrors: 0,
    otherCounty: 0,
    unlocated: 151,
    outside: 0,
    ...over,
  };
}

/** A fake query that records every statement and answers upserts with nothing. */
function fakeQuery() {
  const statements: Array<{ sql: string; params: unknown[] }> = [];
  const query = async (sql: string, params: unknown[] = []) => {
    statements.push({ sql, params });
    return [] as Array<Record<string, unknown>>;
  };
  return { query, statements };
}

/**
 * Which $n a named column is bound to, as a 0-based index into the params array.
 *
 * Reads the INSERT's column list and the VALUES list together, so an assertion can say "this
 * value went into THAT column" instead of "this value is in there somewhere".
 */
function paramIndex(sql: string, column: string): number {
  const cols = sql.slice(sql.indexOf('(') + 1, sql.indexOf(')')).split(',').map((c) => c.trim());
  return cols.indexOf(column);
}

let dir: string;

beforeEach(() => {
  dir = fs.mkdtempSync(path.join(os.tmpdir(), 'cb-import-'));
  fs.mkdirSync(path.join(dir, 'img'), { recursive: true });
});
afterEach(() => { fs.rmSync(dir, { recursive: true, force: true }); });

function writeCounty(row: Record<string, unknown>) {
  fs.writeFileSync(path.join(dir, `${row.geoid}.json`), JSON.stringify(row));
  fs.writeFileSync(path.join(dir, 'img', `${row.geoid}-0.jpg`), 'bytes');
}

describe('importState', () => {
  it('upserts one review row per county with the sweep accounting', async () => {
    writeCounty(countyRow());
    const { query, statements } = fakeQuery();
    const summary = await importState('DE', dir, { query, upload: async () => 'https://x/f.jpg' });

    expect(summary.counties).toBe(1);
    const review = statements.find((s) => s.sql.includes('county_banner_review'));
    expect(review).toBeDefined();
    expect(review!.params).toContain('10001');
    expect(review!.params).toContain('DE');
    expect(review!.params).toContain(77);   // filesSwept
    expect(review!.params).toContain(4);    // categoriesFound
  });

  it('writes candidates keyed on (geoid, commons_title) with rank_position from the array order', async () => {
    const two = countyRow({
      candidates: [candidate({ title: 'File:A.jpg' }), candidate({ title: 'File:B.jpg' })],
    });
    writeCounty(two);
    fs.writeFileSync(path.join(dir, 'img', '10001-1.jpg'), 'bytes');
    const { query, statements } = fakeQuery();
    await importState('DE', dir, { query, upload: async () => 'https://x/f.jpg' });

    // Filter on the INSERT: the resighting report also mentions county_banner_candidates.
    const cands = statements.filter((s) => s.sql.includes('INSERT INTO essentials.county_banner_candidates'));
    expect(cands).toHaveLength(2);
    expect(cands[0].params).toContain('File:A.jpg');
    expect(cands[0].params).toContain(0);
    expect(cands[1].params).toContain('File:B.jpg');
    expect(cands[1].params).toContain(1);
  });

  it('stores the file description page, never the upload URL, as source_page_url', async () => {
    // 🔴 The CHECK on the table refuses an upload.wikimedia.org URL. A raw upload URL names no
    // author and states no terms, so it cannot evidence the licence we published under.
    // Commons writes a title's spaces as underscores; both forms resolve, and this is the
    // canonical one. Changed when M3 fixed the encoding of '?' and '&'.
    expect(descriptionPageUrl('File:Kent County Courthouse.jpg'))
      .toBe('https://commons.wikimedia.org/wiki/File:Kent_County_Courthouse.jpg');

    writeCounty(countyRow());
    const { query, statements } = fakeQuery();
    await importState('DE', dir, { query, upload: async () => 'https://x/f.jpg' });
    const cand = statements.find((s) => s.sql.includes('INSERT INTO essentials.county_banner_candidates'))!;
    const urls = cand.params.filter((p) => typeof p === 'string' && (p as string).includes('wikimedia'));
    expect(urls.every((u) => !String(u).includes('upload.wikimedia.org'))).toBe(true);
  });

  it('PRESERVES an existing decision on re-import', async () => {
    // Review Focus 1. The operator will re-sweep a state after round 2, and a SET list that
    // touched the decision columns would erase the session that produced them.
    writeCounty(countyRow());
    const { query, statements } = fakeQuery();
    await importState('DE', dir, { query, upload: async () => 'https://x/f.jpg' });

    const review = statements.find((s) => s.sql.includes('county_banner_review'))!;
    // 🔴 NORMALISE THE WHITESPACE FIRST. The SET list is column-aligned with runs of spaces, so
    // a raw `not.toContain('status =')` matches nothing whether or not the column is there —
    // the assertion passes vacuously and the guard it is supposed to be is blind. Caught when
    // the POSITIVE assertion below failed for the same reason.
    const setClause = review.sql
      .slice(review.sql.toUpperCase().indexOf('DO UPDATE'))
      .replace(/\s+/g, ' ');
    for (const decisionColumn of ['status', 'chosen_title', 'vertical_anchor', 'focus',
                                  'decided_at', 'decided_by', 'caption_sighted']) {
      expect(setClause).not.toContain(`${decisionColumn} =`);
    }
    // and it DOES refresh the sweep's own columns
    expect(setClause).toContain('files_swept =');
    expect(setClause).toContain('county_name =');
  });

  it('counts a county it could not read into unreadable, and keeps going', async () => {
    writeCounty(countyRow());
    fs.writeFileSync(path.join(dir, '10003.json'), '{"geoid":"10003","swept":tru');  // truncated
    const { query } = fakeQuery();
    const summary = await importState('DE', dir, { query, upload: async () => 'https://x/f.jpg' });
    expect(summary.unreadable).toEqual(['10003.json']);
    expect(summary.counties).toBe(1);
  });

  it('records geometry_candidates and caption_candidates separately, never summed', async () => {
    writeCounty(countyRow());
    const { query, statements } = fakeQuery();
    await importState('DE', dir, { query, upload: async () => 'https://x/f.jpg' });
    const review = statements.find((s) => s.sql.includes('INSERT INTO essentials.county_banner_review'))!;
    // 🔴 ASSERT ON POSITION, NOT MEMBERSHIP. `toContain(1)` and `toContain(0)` both pass if the
    // two lanes are SWAPPED — the params array carries other 0s and 1s — so the test for the
    // repo's "never sum the two lanes" rule used to assert nothing about which value lands in
    // which column. Found in review (I9).
    expect(paramIndex(review.sql, 'geometry_candidates')).toBeGreaterThan(-1);
    expect(review.params[paramIndex(review.sql, 'geometry_candidates')]).toBe(1);
    expect(review.params[paramIndex(review.sql, 'caption_candidates')]).toBe(0);
  });
});

describe('the caption lane reaches the database', () => {
  it('writes caption rows with located_by caption and all three evidence fields', async () => {
    const captioned = countyRow({
      candidates: [candidate({
        title: 'File:Bombay Hook.jpg', lat: null, lon: null,
        locatedBy: 'caption',
        captionText: 'The refuge at Bombay Hook, Delaware',
        captionSourceUrl: 'https://commons.wikimedia.org/wiki/File:Bombay%20Hook.jpg',
        confirmingSourceUrl: 'https://www.flickr.com/photos/x',
        placeListAvailable: false,
      } as never)],
    });
    writeCounty(captioned);
    const { query, statements } = fakeQuery();
    await importState('DE', dir, { query, upload: async () => 'https://x/f.jpg' });

    const cand = statements.find((s) => s.sql.includes('INSERT INTO essentials.county_banner_candidates'))!;
    expect(cand.params).toContain('caption');
    expect(cand.params).toContain('The refuge at Bombay Hook, Delaware');
    expect(cand.params).toContain('https://www.flickr.com/photos/x');
    expect(cand.params).toContain(false);   // placeListAvailable

    // 🔴 and the two lanes stay apart in the county row — by POSITION, so a swap is caught
    const review = statements.find((s) => s.sql.includes('INSERT INTO essentials.county_banner_review'))!;
    expect(review.params[paramIndex(review.sql, 'geometry_candidates')]).toBe(0);
    expect(review.params[paramIndex(review.sql, 'caption_candidates')]).toBe(1);
  });
});

describe('frame keys are stable across sweeps (review C3)', () => {
  it('keys the stored frame on the TITLE, not on the rank position', async () => {
    // 🔴 Positional keys plus x-upsert plus "nothing is ever deleted" = a stale candidate row
    // whose frame_url now serves a DIFFERENT photograph. Sweep 1 gives [A,B,C,D,E] and the
    // operator keeps E at 10001-4.jpg; sweep 2 gives [A,B,C,X,Y] and overwrites 10001-4.jpg
    // with Y's image. Row E is never revisited, so the review page renders Y's photograph
    // under E's title, with a crop certified against an image that is no longer there.
    writeCounty(countyRow({ candidates: [candidate({ title: 'File:E.jpg' })] }));
    const keys: string[] = [];
    const { query } = fakeQuery();
    await importState('DE', dir, { query, upload: async (_p, k) => { keys.push(k); return `https://x/${k}`; } });
    expect(keys[0]).not.toBe('10001-0.jpg');
    expect(keys[0]).toMatch(/^10001-[0-9a-f]{16}\.jpg$/);
  });

  it('gives the same file the same key whatever its rank', async () => {
    const run = async (rank: number) => {
      fs.rmSync(dir, { recursive: true, force: true });
      fs.mkdirSync(path.join(dir, 'img'), { recursive: true });
      const list = [];
      for (let i = 0; i < rank; i++) list.push(candidate({ title: `File:filler${i}.jpg` }));
      list.push(candidate({ title: 'File:E.jpg' }));
      fs.writeFileSync(path.join(dir, '10001.json'), JSON.stringify(countyRow({ candidates: list })));
      for (let i = 0; i <= rank; i++) fs.writeFileSync(path.join(dir, 'img', `10001-${i}.jpg`), 'b');
      const keys: string[] = [];
      const { query } = fakeQuery();
      await importState('DE', dir, { query, upload: async (_p, k) => { keys.push(k); return `https://x/${k}`; } });
      return keys[rank];
    };
    expect(await run(0)).toBe(await run(3));
  });

  it('gives different files different keys', async () => {
    writeCounty(countyRow({
      candidates: [candidate({ title: 'File:A.jpg' }), candidate({ title: 'File:B.jpg' })],
    }));
    fs.writeFileSync(path.join(dir, 'img', '10001-1.jpg'), 'bytes');
    const keys: string[] = [];
    const { query } = fakeQuery();
    await importState('DE', dir, { query, upload: async (_p, k) => { keys.push(k); return `https://x/${k}`; } });
    expect(new Set(keys).size).toBe(2);
  });
});

describe('the importer cannot quietly undermine a decision or a state (review I1, I6)', () => {
  it('reports a county whose KEPT candidate changed how it was located', async () => {
    // 🔴 CANDIDATE_SQL refreshes located_by; REVIEW_SQL deliberately never touches
    // caption_sighted. So a re-import can leave status='keep', caption_sighted=false and a
    // chosen candidate that is NOW caption-located — the service gate never runs, because the
    // importer is not a caller of the service. Review finding I1.
    const { query, statements } = fakeQuery();
    writeCounty(countyRow({
      candidates: [candidate({ title: 'File:A.jpg', locatedBy: 'caption',
        captionText: 'x', captionSourceUrl: 'https://commons.wikimedia.org/wiki/File:A.jpg',
        confirmingSourceUrl: 'https://loc.gov/x' } as never)],
    }));
    // the county already holds an unsighted keep naming that candidate
    statements.length = 0;
    const summary = await importState('DE', dir, {
      query: async (sql: string, p?: unknown[]) => {
        statements.push({ sql, params: p ?? [] });
        if (sql.includes('needs_resighting')) {
          return [{ geoid: '10001', county_name: 'Kent County', chosen_title: 'File:A.jpg' }];
        }
        return [];
      },
      upload: async () => 'https://x/f.jpg',
    });
    expect(summary.needResighting).toEqual([
      { geoid: '10001', countyName: 'Kent County', chosenTitle: 'File:A.jpg' },
    ]);
  });

  it('keeps going when one candidate row is refused, and reports it', async () => {
    writeCounty(countyRow({
      candidates: [candidate({ title: 'File:BAD.jpg' }), candidate({ title: 'File:GOOD.jpg' })],
    }));
    fs.writeFileSync(path.join(dir, 'img', '10001-1.jpg'), 'bytes');
    const seen: string[] = [];
    const summary = await importState('DE', dir, {
      query: async (sql: string, p: unknown[] = []) => {
        if (sql.includes('county_banner_candidates') && String(p[1]).includes('BAD')) {
          throw new Error('violates check constraint "county_banner_candidates_credited"');
        }
        seen.push(sql);
        return [];
      },
      upload: async () => 'https://x/f.jpg',
    });
    // the county row is still written and the good candidate still lands
    expect(summary.counties).toBe(1);
    expect(summary.rejectedRows).toHaveLength(1);
    expect(summary.rejectedRows[0]).toMatch(/BAD/);
    expect(seen.some((s) => s.includes('county_banner_review'))).toBe(true);
  });
});

describe('descriptionPageUrl survives awkward titles (review M3)', () => {
  it('escapes a question mark instead of starting a query string', () => {
    const u = descriptionPageUrl('File:What? And then.jpg');
    expect(u).not.toContain('?');
    expect(u).toContain('File:');
    expect(decodeURIComponent(new URL(u).pathname)).toContain('What? And then.jpg'.replace(/ /g, '_'));
  });

  it('escapes an ampersand', () => {
    expect(descriptionPageUrl('File:Bell & Howell.jpg')).not.toContain('&');
  });

  it('keeps the namespace colon readable, as Commons writes it', () => {
    expect(descriptionPageUrl('File:Kent County Courthouse.jpg'))
      .toBe('https://commons.wikimedia.org/wiki/File:Kent_County_Courthouse.jpg');
  });
});
