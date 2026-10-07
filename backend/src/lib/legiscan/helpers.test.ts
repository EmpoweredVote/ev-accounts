import { describe, it, expect } from 'vitest';
import {
  getNameVariants, normalizeBillStatus, normalizeVoteCast, pickSessionDatasets,
  sessionName, parseIsoDate, jurisdictionFor, committeeChamber, STATE_NAMES,
  type DatasetListEntry,
} from './helpers.js';

const ds = (year_start: number, year_end: number, special = 0): DatasetListEntry => ({
  session_id: year_start * 10 + special, year_start, year_end, special, dataset_hash: 'h', access_key: 'k',
});

describe('pickSessionDatasets', () => {
  it('takes the two newest regular sessions and ignores special sessions', () => {
    const picks = pickSessionDatasets([ds(2021, 2022), ds(2025, 2026), ds(2023, 2024), ds(2025, 2025, 1)]);
    expect(picks.map((p) => [p.label, p.dataset.year_start])).toEqual([['current', 2025], ['previous', 2023]]);
  });
  it('honours a wanted subset', () => {
    const picks = pickSessionDatasets([ds(2025, 2026), ds(2023, 2024)], ['current']);
    expect(picks).toHaveLength(1);
    expect(picks[0].label).toBe('current');
  });
  it('returns nothing when there is no regular session', () => {
    expect(pickSessionDatasets([ds(2025, 2025, 1)])).toEqual([]);
  });
});

describe('names and jurisdictions', () => {
  it('formats session names the way the existing rows are named', () => {
    expect(sessionName('California', { year_start: 2025, year_end: 2026 })).toBe('2025-2026 California Regular Session');
    expect(sessionName('Indiana', { year_start: 2026, year_end: 2026 })).toBe('2026 Indiana Regular Session');
  });
  it('uses lower-case full names as the jurisdiction (matches existing rows)', () => {
    expect(jurisdictionFor('CA')).toBe('california');
    expect(jurisdictionFor('NC')).toBe('north carolina');
  });
  it('knows every state we hold legislators for', () => {
    for (const s of ['AZ','CA','CO','FL','GA','IN','KS','KY','MA','MD','ME','MI','MN','MO','MS','NC','ND','NV','OH','OR','PA','PR','SC','SD','TN','TX','UT','VA','WA','WI']) {
      expect(STATE_NAMES[s]).toBeTruthy();
    }
  });
  it('expands nicknames both ways', () => {
    expect(getNameVariants('Dave')).toEqual(expect.arrayContaining(['dave', 'david']));
    expect(getNameVariants('David')).toEqual(expect.arrayContaining(['david', 'dave']));
    expect(getNameVariants('Zed')).toEqual(['zed']);
  });
});

describe('normalizers', () => {
  it('maps LegiScan status integers', () => {
    expect(normalizeBillStatus(1)).toBe('Introduced');
    expect(normalizeBillStatus(8)).toBe('Signed');
    expect(normalizeBillStatus(7)).toBe('Passed');
  });
  it('falls back to the last action text', () => {
    expect(normalizeBillStatus(undefined, 'Vetoed by Governor')).toBe('Vetoed');
    expect(normalizeBillStatus(undefined, '')).toBe('Introduced');
  });
  it('normalizes vote text; unknown text is not_voting', () => {
    expect(normalizeVoteCast('Yea')).toBe('yea');
    expect(normalizeVoteCast(' NAY ')).toBe('nay');
    expect(normalizeVoteCast('NV')).toBe('not_voting');
    expect(normalizeVoteCast('Excused')).toBe('not_voting');
    expect(normalizeVoteCast(undefined)).toBe('not_voting');
  });
  it('maps committee chambers', () => {
    expect(committeeChamber('H')).toBe('house');
    expect(committeeChamber('s')).toBe('senate');
    expect(committeeChamber('J')).toBe('joint');
  });
  it('accepts only real ISO dates', () => {
    expect(parseIsoDate('2026-02-30')).toBeNull();
    expect(parseIsoDate('2026-02-26')).toBe('2026-02-26');
    expect(parseIsoDate('Feb 26')).toBeNull();
    expect(parseIsoDate(undefined)).toBeNull();
  });
});
