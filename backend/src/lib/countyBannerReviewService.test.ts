import { describe, it, expect } from 'vitest';
import {
  listStates, getStateCounties, recordDecision, isWritable,
  CountyBannerDecisionError, type Decision,
} from './countyBannerReviewService.js';
import type { Queryable } from './seasonService.js';

/** A fake db that answers each query from a scripted list and records what it was asked. */
function fakeDb(answers: Array<Array<Record<string, unknown>>>): Queryable & { seen: string[]; params: unknown[][] } {
  const seen: string[] = [];
  const params: unknown[][] = [];
  let i = 0;
  return {
    seen,
    params,
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    query: (async (sql: string, p?: unknown[]) => {
      seen.push(sql);
      params.push(p ?? []);
      const rows = answers[Math.min(i++, answers.length - 1)] ?? [];
      return { rows, rowCount: rows.length };
    }) as Queryable['query'],
  };
}

const KEEP: Decision = {
  status: 'keep',
  chosenTitle: 'File:A.jpg',
  verticalAnchor: 0.35,
  focus: '50% 30%',
  captionSighted: false,
};

/** The row recordDecision reads to learn how the chosen candidate was located. */
const geometryCandidate = [{ located_by: 'geometry' }];
const captionCandidate = [{ located_by: 'caption' }];

/** What the UPDATE returns: the saved row, which is the only honest source of the save stamp. */
const savedRow = [{
  geoid: '10001', state_usps: 'DE', county_name: 'Kent County', status: 'keep',
  chosen_title: 'File:A.jpg', vertical_anchor: '0.35', focus: '50% 30%', caption_sighted: false,
  swept: true, files_swept: 231, categories_found: 4, category_errors: 0,
  geometry_candidates: 5, caption_candidates: 0, rejected: {},
  decided_at: '2026-11-20T10:00:00.000Z', decided_by: 'tester',
}];

describe('recordDecision', () => {
  it('refuses a keep that names no candidate', async () => {
    const db = fakeDb([geometryCandidate, savedRow]);
    await expect(recordDecision('10001', { ...KEEP, chosenTitle: null }, 'tester', db))
      .rejects.toThrow(CountyBannerDecisionError);
  });

  it('refuses a keep with no focus', async () => {
    const db = fakeDb([geometryCandidate, savedRow]);
    await expect(recordDecision('10001', { ...KEEP, focus: null }, 'tester', db))
      .rejects.toThrow(/focus/i);
  });

  it('refuses a keep whose focus cannot be read as an object-position', async () => {
    const db = fakeDb([geometryCandidate, savedRow]);
    await expect(recordDecision('10001', { ...KEEP, focus: 'centre' }, 'tester', db))
      .rejects.toThrow(/focus/i);
  });

  it('refuses a needs_another_look that names a candidate', async () => {
    // 🔴 The blank ruling. A county the operator rejected ships BLANK, never with the best
    // available option. Standing ruling, Chris Cantrell 2026-11-19.
    const db = fakeDb([geometryCandidate, savedRow]);
    await expect(recordDecision('10001', {
      status: 'needs_another_look', chosenTitle: 'File:A.jpg',
      verticalAnchor: null, focus: null, captionSighted: false,
    }, 'tester', db)).rejects.toThrow(/blank/i);
  });

  it('refuses a vertical anchor outside 0..1', async () => {
    const db = fakeDb([geometryCandidate, savedRow]);
    await expect(recordDecision('10001', { ...KEEP, verticalAnchor: 1.4 }, 'tester', db))
      .rejects.toThrow(/anchor/i);
  });

  it('refuses a caption-located choice when captionSighted is false', async () => {
    // Review Focus 3. A UI-only gate is no gate: the page is not the only caller.
    const db = fakeDb([captionCandidate, savedRow]);
    // The brief wrote /sight/i; the refusal the operator actually reads says "Look at it and
    // confirm it is the place", which is plainer. Assert on what makes the message useful —
    // that it names the caption and asks for a look — rather than on a word it need not use.
    await expect(recordDecision('10001', { ...KEEP, captionSighted: false }, 'tester', db))
      .rejects.toThrow(/caption.*confirm it is the place/is);
  });

  it('accepts a caption-located choice when captionSighted is true', async () => {
    const db = fakeDb([captionCandidate, savedRow]);
    const row = await recordDecision('10001', { ...KEEP, captionSighted: true }, 'tester', db);
    expect(row.status).toBe('keep');
  });

  it('refuses a keep naming a candidate that does not exist', async () => {
    const db = fakeDb([[], savedRow]);
    await expect(recordDecision('10001', KEEP, 'tester', db)).rejects.toThrow(/not a candidate/i);
  });

  it('returns focus byte-identical to what was written', async () => {
    // Review Focus 2. Parsing it into numbers and reformatting is how a silent re-centre hides.
    const db = fakeDb([geometryCandidate, savedRow]);
    const row = await recordDecision('10001', { ...KEEP, focus: '50% 30%' }, 'tester', db);
    expect(row.focus).toBe('50% 30%');
    const writeParams = db.params[1];
    expect(writeParams).toContain('50% 30%');
  });

  it('returns decidedAt from the database row, not from the caller', async () => {
    // 🔴 On 2026-11-19 a crop editor's write path failed on its first call and every later save
    // returned early in silence; the page looked correct the whole time. The save stamp must be
    // what the database says it saved, never what the client hoped.
    const db = fakeDb([geometryCandidate, savedRow]);
    const row = await recordDecision('10001', KEEP, 'tester', db);
    expect(row.decidedAt).toBe('2026-11-20T10:00:00.000Z');
  });

  it('throws when the write returns no row, rather than reporting success', async () => {
    const db = fakeDb([geometryCandidate, []]);
    await expect(recordDecision('10001', KEEP, 'tester', db)).rejects.toThrow(/not saved/i);
  });
});

describe('reads', () => {
  it('isWritable answers from has_table_privilege and writes nothing', async () => {
    const db = fakeDb([[{ writable: true }]]);
    expect(await isWritable(db)).toBe(true);
    expect(db.seen[0]).toContain('has_table_privilege');
    expect(db.seen[0].toUpperCase()).not.toContain('INSERT');
    expect(db.seen[0].toUpperCase()).not.toContain('UPDATE INTO');
  });

  it('listStates counts each status separately', async () => {
    const db = fakeDb([[{ state_usps: 'DE', counties: '3', pending: '2', keep: '1', needs_another_look: '0' }]]);
    const rows = await listStates(db);
    expect(rows[0]).toEqual({ stateUsps: 'DE', counties: 3, pending: 2, keep: 1, needsAnotherLook: 0 });
  });

  it('getStateCounties returns camelCase rows carrying their candidates', async () => {
    const db = fakeDb([[{
      ...savedRow[0],
      candidates: [{
        commons_title: 'File:A.jpg', rank_position: 0, frame_url: 'https://x/f.jpg',
        source_page_url: 'https://commons.wikimedia.org/wiki/File:A.jpg', width: 3000, height: 2000,
        licence: 'cc0', author: 'Someone', located_by: 'geometry',
        caption_text: null, caption_source_url: null, confirming_source_url: null,
        place_list_available: null,
      }],
    }]]);
    const rows = await getStateCounties('DE', db);
    expect(rows[0].countyName).toBe('Kent County');
    expect(rows[0].geometryCandidates).toBe(5);
    expect(rows[0].candidates[0].commonsTitle).toBe('File:A.jpg');
    expect(rows[0].candidates[0].locatedBy).toBe('geometry');
  });

  it('getStateCounties returns an empty candidate list rather than null', async () => {
    const db = fakeDb([[{ ...savedRow[0], candidates: null }]]);
    const rows = await getStateCounties('DE', db);
    expect(rows[0].candidates).toEqual([]);
  });
});
