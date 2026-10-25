import { vi, describe, it, expect } from 'vitest';

// db.js reads env at import; the pure function under test never touches the pool.
vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }));

import { resolveLocalLocations, localToday, type LocalVotingSet, type LocalVotingSite } from './localVotingLocations.js';

const SET: LocalVotingSet = {
  id: 1,
  countyName: 'Monroe County',
  electionName: '2026 General Election',
  electionDate: '2026-11-03',
  sourceLabel: 'Monroe County Election Board — Official 2026 Poll Site Locations',
  sourceUrl: 'https://example.test/monroe',
  lastChecked: '2026-10-22',
  lookupUrl: 'https://indianavoters.in.gov/',
};

const site = (id: number, kind: LocalVotingSite['kind'], precinctCodes: string[], endDate: string | null = null): LocalVotingSite => ({
  id,
  kind,
  name: `Site ${id}`,
  address: `${id} Main St`,
  lat: 39.16,
  lng: -86.53,
  hours: null,
  startDate: null,
  endDate,
  precinctCodes,
});

const SITES = [
  site(1, 'election_day', ['PERRY 01', 'PERRY 29']), // two precincts share a site
  site(2, 'election_day', ['PERRY 02']),
  site(3, 'early_vote', [], '2026-11-02'),
];

const TODAY = '2026-10-22';

describe('resolveLocalLocations', () => {
  it('names the assigned site when the point is well inside one precinct', () => {
    const r = resolveLocalLocations(SET, ['PERRY 02'], ['PERRY 02'], SITES, TODAY);
    expect(r?.electionDaySite?.id).toBe(2);
    expect(r?.nearBoundary).toBe(false);
    expect(r?.earlyVoteSites.map((s) => s.id)).toEqual([3]);
  });

  it('withholds the Election Day site near a line to a precinct that votes elsewhere', () => {
    const r = resolveLocalLocations(SET, ['PERRY 01'], ['PERRY 01', 'PERRY 02'], SITES, TODAY);
    expect(r?.electionDaySite).toBeNull();
    expect(r?.nearBoundary).toBe(true);
    // Early voting is open county-wide, so the line does not matter for it.
    expect(r?.earlyVoteSites).toHaveLength(1);
  });

  it('keeps the site near a line to a precinct that votes at the SAME place', () => {
    const r = resolveLocalLocations(SET, ['PERRY 01'], ['PERRY 01', 'PERRY 29'], SITES, TODAY);
    expect(r?.electionDaySite?.id).toBe(1);
    expect(r?.nearBoundary).toBe(false);
  });

  it('gives no answer outside every precinct, or inside two at once', () => {
    expect(resolveLocalLocations(SET, [], [], SITES, TODAY)).toBeNull();
    expect(resolveLocalLocations(SET, ['PERRY 01', 'PERRY 02'], ['PERRY 01', 'PERRY 02'], SITES, TODAY)).toBeNull();
  });

  it('refuses to guess when a precinct is listed at two sites, or at none', () => {
    const dup = [...SITES, site(4, 'election_day', ['PERRY 02'])];
    expect(resolveLocalLocations(SET, ['PERRY 02'], ['PERRY 02'], dup, TODAY)?.electionDaySite).toBeNull();
    expect(resolveLocalLocations(SET, ['PERRY 99'], ['PERRY 99'], SITES, TODAY)?.electionDaySite).toBeNull();
  });

  it('withholds the site when a nearby precinct has no site of its own', () => {
    const r = resolveLocalLocations(SET, ['PERRY 02'], ['PERRY 02', 'PERRY 99'], SITES, TODAY);
    expect(r?.electionDaySite).toBeNull();
    expect(r?.nearBoundary).toBe(true);
  });

  it('drops the early-vote site once its last day has passed', () => {
    expect(resolveLocalLocations(SET, ['PERRY 02'], ['PERRY 02'], SITES, '2026-11-02')?.earlyVoteSites).toHaveLength(1);
    expect(resolveLocalLocations(SET, ['PERRY 02'], ['PERRY 02'], SITES, '2026-11-03')?.earlyVoteSites).toHaveLength(0);
  });
});

describe('localToday', () => {
  it('uses Indiana time, not UTC', () => {
    // 02:00 UTC on Nov 4 is still 9 pm on Election Day in Bloomington.
    expect(localToday(new Date('2026-11-04T02:00:00Z'))).toBe('2026-11-03');
  });
});
