import { vi, describe, it, expect, beforeEach } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';

// Mock the DB pool so the SQL never actually runs — this is a unit-level test
// of the resolver's mapping/ranking/guard logic. Live index-scan verification
// (EXPLAIN ANALYZE against the real trgm indexes from Plan 03) happens in
// Plan 05's smoke test, per this phase's own verification plan.
vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }));

// FIPS_TO_ABBREV is a static, unambiguous lookup table (no DB access) — mock it
// with a minimal fixture covering the states exercised below.
vi.mock('./essentialsBrowseService.js', () => ({
  FIPS_TO_ABBREV: {
    '06': 'CA', '17': 'IL', '29': 'MO', '25': 'MA', '51': 'VA', '04': 'AZ',
  },
}));

import { pool } from './db.js';
import { searchPlaceNames, LocationSearchQueryTooShortError, cleanPlaceName } from './locationSearchService.js';

const read = (rel: string) => fs.readFileSync(path.resolve(__dirname, rel), 'utf-8');
const SOURCE = read('./locationSearchService.ts');

// Builds a mock DB row matching the shape the resolver's SQL is expected to
// return (see the file's LocationSearchRow interface).
function row(overrides: Partial<Record<string, unknown>>) {
  return {
    geo_id: '',
    mtfcc: '',
    name: '',
    gov_state: null,
    geofence_state_fips: null,
    gov_type: null,
    has_local_data: false,
    sim: 0.5,
    exact_match: false,
    ...overrides,
  };
}

describe('searchPlaceNames', () => {
  beforeEach(() => {
    vi.mocked(pool.query).mockReset();
  });

  it('rejects queries shorter than 2 characters without hitting the DB', async () => {
    await expect(searchPlaceNames('a', 10)).rejects.toBeInstanceOf(LocationSearchQueryTooShortError);
    expect(pool.query).not.toHaveBeenCalled();
  });

  it('Springfield: returns multiple candidates spanning distinct states — never a silent pick', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({
      rows: [
        row({ geo_id: '1772000', name: 'Springfield', mtfcc: 'G4110', gov_state: 'IL', gov_type: 'City', has_local_data: true, sim: 0.9, exact_match: true }),
        row({ geo_id: '2965000', name: 'Springfield city', mtfcc: 'G4110', gov_state: 'MO', gov_type: null, has_local_data: false, sim: 0.85, exact_match: false }),
        row({ geo_id: '2562535', name: 'Springfield city', mtfcc: 'G4110', gov_state: 'MA', gov_type: null, has_local_data: false, sim: 0.8, exact_match: false }),
      ],
    } as never);

    const results = await searchPlaceNames('Springfield', 10);

    expect(results).toHaveLength(3);
    const states = new Set(results.map((r) => r.state));
    expect(states).toEqual(new Set(['IL', 'MO', 'MA']));
  });

  it('Baltimore: returns both a City candidate and a County candidate, each labeled per D-05', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({
      rows: [
        row({ geo_id: '2404000', name: 'Baltimore city', mtfcc: 'G4110', gov_state: 'MD', gov_type: 'City', has_local_data: true, sim: 0.95 }),
        row({ geo_id: '24005', name: 'Baltimore County', mtfcc: 'G4020', gov_state: 'MD', gov_type: 'County', has_local_data: false, sim: 0.9 }),
      ],
    } as never);

    const results = await searchPlaceNames('Baltimore', 10);

    expect(results.map((r) => r.area_type).sort()).toEqual(['City', 'County']);
    for (const r of results) {
      expect(r.label).toMatch(/^Baltimore.*, MD ·/);
    }
  });

  it('Franklin, VA: returns multiple state-qualified candidates (independent city + county + other states)', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({
      rows: [
        row({ geo_id: '5129032', name: 'Franklin city', mtfcc: 'G4110', gov_state: 'VA', gov_type: 'City', has_local_data: false, sim: 0.8 }),
        row({ geo_id: '51067', name: 'Franklin County', mtfcc: 'G4020', gov_state: 'VA', gov_type: 'County', has_local_data: false, sim: 0.75 }),
        row({ geo_id: '4726820', name: 'Franklin', mtfcc: 'G4110', gov_state: 'TN', gov_type: null, has_local_data: false, sim: 0.7 }),
      ],
    } as never);

    const results = await searchPlaceNames('Franklin', 10);

    expect(results).toHaveLength(3);
    expect(results.every((r) => r.state.length > 0)).toBe(true);
    const vaCandidates = results.filter((r) => r.state === 'VA');
    expect(vaCandidates.map((r) => r.area_type).sort()).toEqual(['City', 'County']);
  });

  it('candidate shape is exactly {geo_id, mtfcc, label, state, area_type, has_local_data} — explicit whitelist', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({
      rows: [row({ geo_id: '1772000', name: 'Springfield', mtfcc: 'G4110', gov_state: 'IL', gov_type: 'City', has_local_data: true, sim: 0.9 })],
    } as never);

    const [candidate] = await searchPlaceNames('Springfield', 10);

    expect(Object.keys(candidate).sort()).toEqual(
      ['area_type', 'geo_id', 'has_local_data', 'label', 'mtfcc', 'state'].sort()
    );
  });

  it('label format is "Name, ST · Type" for City/County rows', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({
      rows: [row({ geo_id: '1772000', name: 'Springfield', mtfcc: 'G4110', gov_state: 'IL', gov_type: 'City', has_local_data: true, sim: 0.9 })],
    } as never);

    const [candidate] = await searchPlaceNames('Springfield', 10);
    expect(candidate.label).toBe('Springfield, IL · City');
  });

  it('label format is "Name · State" (no redundant abbrev) for State rows', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({
      rows: [row({ geo_id: '17', name: 'Illinois', mtfcc: '', gov_state: 'IL', gov_type: 'State', has_local_data: true, sim: 1, exact_match: true })],
    } as never);

    const [candidate] = await searchPlaceNames('Illinois', 10);
    expect(candidate.label).toBe('Illinois · State');
    expect(candidate.area_type).toBe('State');
  });

  it('state is sourced from the matched row\'s own state column, never derived from the query string (wrong-state guard)', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({
      rows: [row({ geo_id: '2965000', name: 'Springfield city', mtfcc: 'G4110', gov_state: 'MO', gov_type: 'City', has_local_data: true, sim: 0.9 })],
    } as never);

    // Query text itself carries no state hint at all.
    const results = await searchPlaceNames('springfield', 10);
    expect(results[0].state).toBe('MO');
  });

  it('has_local_data is false for a Gazetteer-only place with no curated government, but state is still valid', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({
      rows: [row({ geo_id: '0452930', name: 'Paradise Valley town', mtfcc: 'G4110', gov_state: 'AZ', gov_type: 'City', has_local_data: false, sim: 0.7 })],
    } as never);

    const results = await searchPlaceNames('Paradise', 10);
    expect(results[0].has_local_data).toBe(false);
    expect(results[0].state).toBe('AZ');
  });

  it('falls back to mapping a geofence FIPS state code to a USPS abbrev when the matched row has no direct state', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({
      rows: [row({ geo_id: '0667000', name: 'San Francisco', mtfcc: 'G4110', gov_state: null, geofence_state_fips: '06', gov_type: 'City', has_local_data: true, sim: 0.9 })],
    } as never);

    const results = await searchPlaceNames('San Francisco', 10);
    expect(results[0].state).toBe('CA');
  });

  it('a single already-deduped curated row maps to exactly one candidate (no fan-out)', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({
      rows: [row({ geo_id: '0455000', name: 'Tucson', mtfcc: 'G4110', gov_state: 'AZ', gov_type: 'City', has_local_data: true, sim: 0.95, exact_match: true })],
    } as never);

    const results = await searchPlaceNames('Tucson', 10);
    expect(results).toHaveLength(1);
  });

  it('212-06 gap closure: a curated government with a NULL governments.geo_id resolves to its linked G4110 district geo_id — has_local_data:true, exactly ONE candidate (deduped with the gazetteer twin)', async () => {
    // Simulates the SQL's COALESCE(g.geo_id, place_district.district_geo_id) already
    // having resolved "City of Bloomington, Indiana, US" (governments.geo_id NULL) to
    // its linked G4110 district geo_id 1805860 — the same geo_id the gazetteer/geofence
    // twin ("Bloomington city, IN") carries, so the SQL-side DISTINCT ON (geo_id)
    // ORDER BY geo_id, source_boost DESC collapses them into this single curated row.
    vi.mocked(pool.query).mockResolvedValueOnce({
      rows: [
        row({
          geo_id: '1805860',
          // Real production governments.name shape — carries the redundant
          // "City of …, Indiana, US" qualifiers that must NOT leak into the label.
          name: 'City of Bloomington, Indiana, US',
          mtfcc: 'G4110',
          gov_state: 'IN',
          gov_type: 'City',
          has_local_data: true,
          sim: 0.95,
          exact_match: true,
        }),
      ],
    } as never);

    const results = await searchPlaceNames('Bloomington', 10);

    expect(results).toHaveLength(1);
    expect(results[0].geo_id).toBe('1805860');
    expect(results[0].geo_id).not.toBeNull();
    expect(results[0].has_local_data).toBe(true);
    expect(results[0].state).toBe('IN');
    // Label is the bare place string — no "City of", no ", Indiana, US".
    expect(results[0].label).toBe('Bloomington, IN · City');
  });

  it('passes only the effective query and limit as parameterized values', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [] } as never);
    await searchPlaceNames('Tucson', 5);
    const [, params] = vi.mocked(pool.query).mock.calls[0];
    expect(params).toEqual(['Tucson', 5]);
  });

  it('expands a bare 2-letter state abbreviation to its full name before matching (static 50-state exact match)', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({ rows: [] } as never);
    await searchPlaceNames('IL', 10);
    const [, params] = vi.mocked(pool.query).mock.calls[0];
    expect(params![0]).toBe('Illinois');
  });
});

describe('cleanPlaceName (D-05 bare-label normalization, 2026-07-23)', () => {
  it('strips a leading "City of" and a trailing ", {state}, US" (curated government name)', () => {
    expect(cleanPlaceName('City of Bloomington, Indiana, US')).toBe('Bloomington');
    expect(cleanPlaceName('City of Falls Church, Virginia, US')).toBe('Falls Church');
  });

  it('keeps County / Township / Unified suffixes (only leading civic designators are dropped)', () => {
    expect(cleanPlaceName('Morgan County, Indiana, US')).toBe('Morgan County');
    expect(cleanPlaceName('Bloomington Township, Indiana, US')).toBe('Bloomington Township');
    expect(cleanPlaceName('Pomona Unified, California, US')).toBe('Pomona Unified');
  });

  it('strips a trailing lowercase Census type token (gazetteer name)', () => {
    expect(cleanPlaceName('Bloomington city')).toBe('Bloomington');
    expect(cleanPlaceName('Baltimore city')).toBe('Baltimore');
    expect(cleanPlaceName('Paradise Valley town')).toBe('Paradise Valley');
    expect(cleanPlaceName('Bloomington CDP')).toBe('Bloomington');
  });

  it('never over-strips a mid-name capitalized "City" (Kansas City guard)', () => {
    expect(cleanPlaceName('Kansas City city')).toBe('Kansas City');
    expect(cleanPlaceName('Kansas City')).toBe('Kansas City');
  });

  it('leaves an already-bare name and a full state name untouched', () => {
    expect(cleanPlaceName('Springfield')).toBe('Springfield');
    expect(cleanPlaceName('Illinois')).toBe('Illinois');
  });
});

describe('label uses the bare place string end-to-end', () => {
  beforeEach(() => {
    vi.mocked(pool.query).mockReset();
  });

  it('a verbose curated name and a Census gazetteer twin both resolve to a clean "Name, ST · Type" label', async () => {
    vi.mocked(pool.query).mockResolvedValueOnce({
      rows: [
        row({ geo_id: '2404000', name: 'Baltimore city', mtfcc: 'G4110', gov_state: 'MD', gov_type: 'City', has_local_data: false, sim: 0.9 }),
        row({ geo_id: '24005', name: 'Baltimore County, Maryland, US', mtfcc: 'G4020', gov_state: 'MD', gov_type: 'County', has_local_data: true, sim: 0.85 }),
      ],
    } as never);

    const results = await searchPlaceNames('Baltimore', 10);
    expect(results.map((r) => r.label)).toEqual(['Baltimore, MD · City', 'Baltimore County, MD · County']);
  });
});

describe('locationSearchService.ts source guards', () => {
  it('does not import geocodeAddress (Census one-line geocoder stays street-address-only)', () => {
    expect(SOURCE).not.toMatch(/geocodeAddress/);
  });

  it('does not import or reference coverage.js (has_local_data must come from a live DB check)', () => {
    expect(SOURCE).not.toMatch(/coverage\.js/);
  });

  it('never orders or derives ranking from a population column (amended D-06, 2026-07-20)', () => {
    // Scope the check to the actual SQL text (between the `const sql = ` +
    // template literal delimiters), not the surrounding explanatory comments
    // — this file's own doc comments legitimately discuss *why* population
    // is never used as a tiebreak, which would otherwise false-positive a
    // whole-file substring check.
    const sqlStart = SOURCE.indexOf('const sql = `');
    const sqlEnd = SOURCE.indexOf('`;', sqlStart);
    const sqlText = SOURCE.slice(sqlStart, sqlEnd).toLowerCase();
    expect(sqlText).not.toMatch(/population|pop_/);
  });

  it('tertiary ORDER BY tiebreak is name ASC, not population', () => {
    expect(SOURCE).toMatch(/ORDER BY source_boost DESC, sim DESC, exact_match DESC, name ASC/);
  });

  it('the curated CTE dedupes to one row per governments.id via DISTINCT ON (g.id)', () => {
    expect(SOURCE).toMatch(/DISTINCT ON \(g\.id\)/);
  });

  it('the combined result is deduped by geo_id, preferring the curated (higher source_boost) row', () => {
    expect(SOURCE).toMatch(/DISTINCT ON \(geo_id\)/);
    expect(SOURCE).toMatch(/ORDER BY geo_id, source_boost DESC/);
  });

  it('only $1/$2 placeholders carry user input; no $3 or higher parameter exists', () => {
    expect(SOURCE).not.toMatch(/\$3/);
  });

  it('threshold is the only interpolated value, derived from the effective query length', () => {
    expect(SOURCE).toMatch(/effectiveQuery\.length/);
    expect(SOURCE).toMatch(/\$\{threshold\}/);
  });

  it('has_local_data is computed via a live EXISTS check on chambers, not a static list', () => {
    expect(SOURCE).toMatch(/EXISTS\s*\(\s*SELECT 1 FROM essentials\.chambers/);
  });

  it('212-06: curated CTE resolves a NULL governments.geo_id via a LATERAL chambers->offices->districts lookup filtered to G4110/G4020', () => {
    expect(SOURCE).toMatch(/LEFT JOIN LATERAL/);
    expect(SOURCE).toMatch(/d\.mtfcc IN \('G4110', 'G4020'\)/);
    expect(SOURCE).toMatch(/COALESCE\(g\.geo_id, place_district\.district_geo_id\)/);
    expect(SOURCE).toMatch(/COALESCE\(gb\.mtfcc, place_district\.district_mtfcc\)/);
  });

  it('212-06: the place_district LATERAL only fires when governments.geo_id IS NULL (never overrides an existing geo_id)', () => {
    expect(SOURCE).toMatch(/\)\s*place_district\s*ON\s*g\.geo_id IS NULL/);
  });
});
