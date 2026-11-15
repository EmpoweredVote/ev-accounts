import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { buildRollCall, INDEX, type IndexedVote } from './fetch-legislature-rollcalls.js';

// The saved Utah House page: roll call 100 of the 2025 General Session, HB 237, 71 yeas, 0 nays, 4 absent.
const HOUSE = readFileSync(fileURLToPath(new URL('../../../src/lib/__fixtures__/stateRollCall/ut-2025GS-100-H.html', import.meta.url)), 'latin1');
const URL_H = 'https://le.utah.gov/DynaBill/svotes.jsp?sessionid=2025GS&voteid=100&house=H';
const vote = (over: Partial<IndexedVote> = {}): IndexedVote => ({ url: URL_H, motion: 'House/ passed 3rd reading', tally: [71, 0, 4], ...over });
/** A bill's vote list as le.utah.gov publishes it, cut down to the fields the tool reads. */
const action = (over: Record<string, string>): Record<string, string> =>
  ({ description: 'House/ passed 3rd reading', actionClass: 'H', voteID: '100', voiceVote: '0', voteHouse: 'H', voteStr: '71-0-4', ...over });
const file = (actions: Record<string, string>[], over: Record<string, string> = {}): string =>
  JSON.stringify({ sessionID: '2025GS', billNumber: 'HB0237', actionHistoryList: actions, ...over });

describe('the legislature\'s own vote list — Utah', () => {
  it('names the data file by the site\'s session and bill numbers', () => {
    expect(INDEX.UT.billUrl('2025', 'HB 237')).toBe('https://le.utah.gov/data/2025GS/HB0237.json');
    expect(INDEX.UT.billUrl('2025S1', 'S.J.R. 2')).toBe('https://le.utah.gov/data/2025S1/SJR0002.json');
    expect(INDEX.UT.billUrl('2025-2026', 'HB 237')).toBeNull();
    expect(INDEX.UT.billUrl('2025', 'Bill 237')).toBeNull();
  });

  it('keeps floor roll calls and counts, but does not read, committee and voice votes', () => {
    const bi = INDEX.UT.read(file([
      action({}),
      action({ actionClass: 'A', voteID: '34263', voteHouse: '', voteStr: '9-0-2', voiceVote: '' }),
      action({ voteID: '302', voiceVote: '1', voteStr: '0-0-75' }),
      action({ voteID: '' }),
      action({ actionClass: 'S', voteID: '734', voteHouse: 'S', voteStr: ' 19-0-10 ', description: 'Senate/ passed 2nd reading' }),
    ]), '2025', 'HB 237');
    expect(bi.committee).toBe(1);
    expect(bi.voice).toBe(1);
    expect(bi.floor).toEqual([
      { url: URL_H, motion: 'House/ passed 3rd reading', tally: [71, 0, 4] },
      { url: 'https://le.utah.gov/DynaBill/svotes.jsp?sessionid=2025GS&voteid=734&house=S', motion: 'Senate/ passed 2nd reading', tally: [19, 0, 10] },
    ]);
  });

  it('refuses a data file that is for another bill or another session', () => {
    expect(() => INDEX.UT.read(file([action({})]), '2025', 'HB 238')).toThrow(/not 2025 HB 238/);
    expect(() => INDEX.UT.read(file([action({})], { sessionID: '2024GS' }), '2025', 'HB 237')).toThrow(/2024GS/);
  });

  it('refuses a floor vote it cannot read, rather than dropping it', () => {
    expect(() => INDEX.UT.read(file([action({ voteStr: 'passed' })]), '2025', 'HB 237')).toThrow(/cannot read/);
    expect(() => INDEX.UT.read(file([action({ voteHouse: '' })]), '2025', 'HB 237')).toThrow(/cannot read/);
  });
});

describe('one roll call for the supplement', () => {
  it('takes the members from the page when the page and the bill file agree', () => {
    const rc = buildRollCall('HB 237', vote(), HOUSE);
    expect(rc).toMatchObject({ url: URL_H, date: '2025-01-30', chamber: 'H', yea: 71, nay: 0, absent: 4, passed: 1,
      motion: 'House/ passed 3rd reading', question: '3rd Reading Final Passage' });
    if ('refused' in rc) throw new Error(rc.refused);
    expect(rc.groups['Absent or not voting']).toEqual(['Bolinder, B.', 'Matthews, A.', 'Schultz, M.', 'Teuscher, J.']);
    expect(rc.groups.Yea).toContain('Maloy, A. Cory');
  });

  it('refuses a page that is for another bill', () => {
    expect(buildRollCall('HB 238', vote(), HOUSE)).toEqual({ refused: 'the page is for HB 237, not HB 238' });
  });

  it('refuses a page whose tally is not the bill file\'s', () => {
    expect(buildRollCall('HB 237', vote({ tally: [70, 1, 4] }), HOUSE)).toEqual({ refused: 'the page\'s tally 71-0-4 is not the bill file\'s 70-1-4' });
  });

  it('refuses a page the reader refuses, and an address no reader knows', () => {
    expect(HOUSE.includes('Yeas - 71')).toBe(true);
    expect(buildRollCall('HB 237', vote(), HOUSE.replace('Yeas - 71', 'Yeas - 70'))).toEqual({ refused: 'the page did not read as a roll call' });
    expect(buildRollCall('HB 237', vote({ url: 'https://le.utah.gov/mtgvotes.jsp?voteid=9' }), HOUSE)).toEqual({ refused: 'no reader knows this address' });
  });

  it('takes pass or fail from the motion\'s own word, and from the count only when it has none', () => {
    const p = (motion: string): unknown => { const rc = buildRollCall('HB 237', vote({ motion }), HOUSE); return 'refused' in rc ? rc : rc.passed; };
    expect(p('House/ failed')).toBe(0);
    expect(p('House/ concurs with Senate amendment')).toBe(1);
    expect(p('House/ substituted')).toBe(1); // 71 yeas to 0
  });
});
