import { fileURLToPath } from 'node:url';
import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { listVoteDocuments, parseFeedTally, parseLegislationFeed } from './feed.js';
import { EXCEPTION_CAUSES } from '../types.js';

const load = (name: string): unknown =>
  JSON.parse(readFileSync(new URL(`./__fixtures__/${name}`, import.meta.url), 'utf8'));

const BASE = 'https://bloomington.in.gov';

describe('parseFeedTally', () => {
  it.each([
    ['5 - 2 (Flaherty, Ruff) - 0 (Rosenbarger, Zulich absent)', { yes: 5, no: 2, abstain: 0 }],
    ['7-0-0 (Rosenbarger, Zulich absent)', { yes: 7, no: 0, abstain: 0 }],
    ['6-1 (Asare) (Flaherty, Rosenbarger absent)', { yes: 6, no: 1, abstain: 0 }],
    ['9-0', { yes: 9, no: 0, abstain: 0 }],
    ['7-0 (Rosenbarger left at 10:40pm, Zulich absent)', { yes: 7, no: 0, abstain: 0 }],
    ['pending', null],
  ])('%s', (input, expected) => {
    expect(parseFeedTally(input)).toEqual(expected);
  });
});

describe('parseLegislationFeed', () => {
  const items = parseLegislationFeed(load('legislation-2026.json'), BASE);

  it('returns every item', () => {
    expect(items).toHaveLength(54);
  });

  it('sets firstActionDate to the earliest action date', () => {
    const [item] = parseLegislationFeed(
      [
        {
          id: 1, type: 'Ordinance', number: '2026-01', year: 2026, status: 'Adopted', title: 't',
          actions: [
            { name: 'Final', date: '2026-03-04', outcome: 'pass', vote: '9-0' },
            { name: 'Introduced', date: '2026-02-04' },
          ],
        },
        { id: 2, type: 'Ordinance', number: '2026-02', year: 2026, status: 'Introduced', title: 't', actions: [] },
      ],
      BASE,
    );
    expect(item.firstActionDate).toBe('2026-02-04');
    const none = parseLegislationFeed(
      [{ id: 2, type: 'Ordinance', number: '2026-02', year: 2026, status: 'Introduced', title: 't', actions: [] }],
      BASE,
    );
    expect(none[0].firstActionDate).toBeNull();
  });

  it('reads Ord 2026-37', () => {
    const item = items.find((i) => i.feedId === 6435)!;
    expect(item.itemNumber).toBe('Ord 2026-37');
    expect(item.final?.date).toBe('2026-11-04');
    expect(item.final?.outcome).toBe('passed');
    expect(item.final?.tally).toEqual({ yes: 7, no: 0, abstain: 0 });
    expect(item.pageUrl.endsWith('/Ordinance/2026/2026-37')).toBe(true);
    expect(item.pageUrl).toBe(`${BASE}/council/legislation/Ordinance/2026/2026-37`);
  });

  it('numbers resolutions and appropriation ordinances', () => {
    expect(items.some((i) => i.itemNumber.startsWith('Res '))).toBe(true);
    expect(items.some((i) => i.itemNumber.startsWith('App Ord '))).toBe(true);
    const app = items.find((i) => i.type === 'Appropriation Ordinance')!;
    expect(app.pageUrl).toContain('/Appropriation%20Ordinance/');
  });

  it('marks a vetoed item as vetoed and an item with no Final as null', () => {
    const out = parseLegislationFeed(
      [
        { id: 1, type: 'Ordinance', number: '2026-01', year: 2026, status: 'Vetoed', title: 't', synopsis: null,
          actions: [{ name: 'Final', date: '2026-01-01', outcome: 'fail', vote: '4-5' }], files: [] },
        { id: 2, type: 'Resolution', number: '2026-02', year: 2026, status: 'Introduced', title: 't', synopsis: null,
          actions: [], files: [] },
      ],
      BASE,
    );
    expect(out[0].final?.outcome).toBe('vetoed');
    expect(out[1].final).toBeNull();
  });
});

describe('parseLegislationFeed edge cases', () => {
  const mk = (outcome: string, vote: string) => [
    { id: 77, type: 'Ordinance', number: '2026-99', year: 2026, status: 'Adopted', title: 't', synopsis: null,
      actions: [{ name: 'Final', date: '2026-02-02', outcome, vote }], files: [] },
  ];

  it('keeps date and outcome when the vote text cannot be read', () => {
    const [item] = parseLegislationFeed(mk('pass', 'voice vote'), BASE);
    expect(item.final).toEqual({ date: '2026-02-02', outcome: 'passed', tally: null });
  });

  it('throws on an unknown outcome, naming the feed id and value', () => {
    expect(() => parseLegislationFeed(mk('tabled', '5-4'), BASE)).toThrow(/tabled.*77/);
  });
});

describe('listVoteDocuments', () => {
  const files = listVoteDocuments(load('meetings-2026.json'));

  it('returns Minutes and Memorandum files with https download urls', () => {
    expect(files.length).toBeGreaterThan(0);
    for (const f of files) {
      expect(f.url.startsWith('https://')).toBe(true);
      expect(f.meetingDate).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    }
    expect(files.find((f) => f.fileId === 17742)).toMatchObject({
      meetingId: 11960,
      meetingDate: '2026-08-05',
      kind: 'minutes',
    });
    expect(files.find((f) => f.fileId === 17565)).toMatchObject({
      meetingId: 11969,
      meetingDate: '2026-10-07',
      kind: 'memorandum',
    });
    expect(new Set(files.map((f) => f.kind))).toEqual(new Set(['minutes', 'memorandum']));
  });

  it('skips Memorandum files of meetings that are not council sessions (interview committees)', () => {
    expect(files.find((f) => f.fileId === 17753)).toBeUndefined();
  });

  it('skips meetings that are not Common Council sessions', () => {
    const out = listVoteDocuments({
      '2026-01-01': {
        '18:00:00': [
          { id: 1, title: 'Plan Commission', files: { Minutes: [{ id: 9, type: 'Minutes', url: 'https://x/9', updated: 'u' }] } },
          { id: 4, title: 'Plan Commission', files: { Memorandum: [{ id: 7, type: 'Memorandum', url: 'https://x/7', updated: 'u' }] } },
          { id: 2, title: 'Common Council Regular Session', files: [] },
          { id: 3, title: 'Common Council Regular Session', files: { Agenda: [{ id: 8, type: 'Agenda', url: 'https://x/8', updated: 'u' }] } },
        ],
      },
    });
    expect(out).toEqual([]);
  });
});

describe('EXCEPTION_CAUSES', () => {
  it('has 15 causes including minutes_disagree and the two sponsor causes', () => {
    expect(EXCEPTION_CAUSES).toHaveLength(15);
    expect(EXCEPTION_CAUSES).toContain('minutes_disagree');
    expect(EXCEPTION_CAUSES).toContain('sponsor_unresolved');
    expect(EXCEPTION_CAUSES).toContain('sponsor_disagrees');
  });

  it('equals the cause CHECK list in CA_0436', () => {
    const sql = readFileSync(
      fileURLToPath(new URL('../../../../migrations/CA_0436_local_record_sponsor_causes.sql', import.meta.url)),
      'utf8',
    );
    const m = sql.match(/ADD CONSTRAINT local_record_exceptions_cause_check CHECK \(cause IN \(([^)]*)\)\)/);
    expect(m).not.toBeNull();
    const listed = [...m![1].matchAll(/'([a-z_]+)'/g)].map((x) => x[1]);
    expect([...listed].sort()).toEqual([...EXCEPTION_CAUSES].sort());
  });
});

describe('R8: Organizational Meetings are council sessions', () => {
  it('lists the 2026-01-07 Organizational Meeting minutes (file 17231) and memorandum (16067), with file names', () => {
    const files = listVoteDocuments(load('meetings-2026.json'));
    expect(files.find((f) => f.fileId === 17231)).toMatchObject({
      meetingId: 11878, meetingDate: '2026-01-07', kind: 'minutes', fileName: '2026.01.07.OM.mins.revised.signed.pdf',
      meetingTitle: 'Common Council Organizational Meeting',
    });
    expect(files.find((f) => f.fileId === 16067)).toMatchObject({ kind: 'memorandum' });
  });

  it('still skips a committee\'s organizational meeting that is not the Common Council', () => {
    const out = listVoteDocuments({
      '2022-03-01': { '17:00:00': [{ id: 5201, title: 'Jack Hopkins - Organizational Meeting', files: { Minutes: [{ id: 1, type: 'Minutes', url: 'https://x/1', updated: 'u' }] } }] },
    });
    expect(out).toEqual([]);
  });
});
