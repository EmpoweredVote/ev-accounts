import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { listMinutesFiles, parseFeedTally, parseLegislationFeed } from './feed.js';

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

describe('listMinutesFiles', () => {
  const files = listMinutesFiles(load('meetings-2026.json'));

  it('returns only Minutes files with https download urls', () => {
    expect(files.length).toBeGreaterThan(0);
    for (const f of files) {
      expect(f.url.startsWith('https://')).toBe(true);
      expect(f.meetingDate).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    }
    expect(files.find((f) => f.fileId === 17742)).toMatchObject({
      meetingId: 11960,
      meetingDate: '2026-08-05',
    });
  });

  it('skips meetings that are not Common Council sessions', () => {
    const out = listMinutesFiles({
      '2026-01-01': {
        '18:00:00': [
          { id: 1, title: 'Plan Commission', files: { Minutes: [{ id: 9, type: 'Minutes', url: 'https://x/9', updated: 'u' }] } },
          { id: 2, title: 'Common Council Regular Session', files: [] },
          { id: 3, title: 'Common Council Regular Session', files: { Agenda: [{ id: 8, type: 'Agenda', url: 'https://x/8', updated: 'u' }] } },
        ],
      },
    });
    expect(out).toEqual([]);
  });
});
