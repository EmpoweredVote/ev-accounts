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

    const cands = statements.filter((s) => s.sql.includes('county_banner_candidates'));
    expect(cands).toHaveLength(2);
    expect(cands[0].params).toContain('File:A.jpg');
    expect(cands[0].params).toContain(0);
    expect(cands[1].params).toContain('File:B.jpg');
    expect(cands[1].params).toContain(1);
  });

  it('stores the file description page, never the upload URL, as source_page_url', async () => {
    // 🔴 The CHECK on the table refuses an upload.wikimedia.org URL. A raw upload URL names no
    // author and states no terms, so it cannot evidence the licence we published under.
    expect(descriptionPageUrl('File:Kent County Courthouse.jpg'))
      .toBe('https://commons.wikimedia.org/wiki/File:Kent%20County%20Courthouse.jpg');

    writeCounty(countyRow());
    const { query, statements } = fakeQuery();
    await importState('DE', dir, { query, upload: async () => 'https://x/f.jpg' });
    const cand = statements.find((s) => s.sql.includes('county_banner_candidates'))!;
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
    const review = statements.find((s) => s.sql.includes('county_banner_review'))!;
    expect(review.sql).toContain('geometry_candidates');
    expect(review.sql).toContain('caption_candidates');
    // one geometry candidate, no caption lane yet
    expect(review.params).toContain(1);
    expect(review.params).toContain(0);
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

    const cand = statements.find((s) => s.sql.includes('county_banner_candidates'))!;
    expect(cand.params).toContain('caption');
    expect(cand.params).toContain('The refuge at Bombay Hook, Delaware');
    expect(cand.params).toContain('https://www.flickr.com/photos/x');
    expect(cand.params).toContain(false);   // placeListAvailable

    // 🔴 and the two lanes stay apart in the county row
    const review = statements.find((s) => s.sql.includes('county_banner_review'))!;
    const geomIdx = review.sql.split(',').findIndex((c) => c.includes('geometry_candidates'));
    expect(geomIdx).toBeGreaterThan(-1);
    expect(review.params).toContain(0);   // geometry_candidates: none
    expect(review.params).toContain(1);   // caption_candidates: one
  });
});
