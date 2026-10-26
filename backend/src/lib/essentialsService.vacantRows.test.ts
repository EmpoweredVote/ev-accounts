import { vi, describe, it, expect, beforeEach } from 'vitest';

// Mock DB and geocoding so module-level side effects don't crash the runner —
// same preamble as essentialsService.test.ts.
vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }));
vi.mock('./geocodingService.js', () => ({
  geocodeAddress: vi.fn(),
  GeocodingError: class GeocodingError extends Error {},
}));

import { pool } from './db.js';
import { getRepresentativesByCoordinate } from './essentialsService.js';

/**
 * A VACANT SEAT IS NOT A PERSON WITH NO NAME.
 *
 * `office_current_holder` LEFT JOINs from `offices`, so the address path emits an empty seat
 * as a row whose p.* columns are all NULL. Before this, `PoliticianFlatRecord.id` was typed
 * `string` and the mapper cast the NULL straight through, so the response carried a row that
 * looked like a broken person: `id: null`, `full_name: ''`, and no key of any kind — the
 * whole politician surface had no office id. Measured live on 2026-10-26, a Santa Clarita
 * address returned two such rows.
 *
 * These pin the three decisions that fix it, and the third is the one that will be "simplified"
 * away: `seat_status` is derived from WHETHER A HOLDER RESOLVED, never from `is_vacant`.
 */

type Row = Record<string, unknown>;

/** A district-query row. Nulls where the LEFT JOIN would leave them. */
function districtRow(over: Row): Row {
  return {
    id: null,
    external_id: null,
    full_name: null,
    first_name: null,
    last_name: null,
    office_id: 'office-unset',
    office_title: 'Council Member',
    district_type: 'LOCAL',
    district_label: 'District 1',
    district_id: '1',
    geo_id: 'x-1',
    mtfcc: 'X0001',
    government_name: 'City of Testville, Testland, US',
    is_vacant: false,
    vacant_since: null,
    ...over,
  };
}

const HELD = districtRow({
  id: 'politician-1',
  full_name: 'Held Person',
  office_id: 'office-held',
});

const VACANT = districtRow({
  office_id: 'office-vacant',
  office_title: 'Council Member (District 2)',
  is_vacant: true,
  vacant_since: '2025-11-01',
});

/** 🔴 The `is_vacant` trap: flagged vacant, yet a term resolved a holder. */
const FLAGGED_BUT_HELD = districtRow({
  id: 'politician-3',
  full_name: 'Flagged But Held',
  office_id: 'office-flagged-held',
  is_vacant: true,
  vacant_since: '2026-01-15',
});

/** Answer the district query with our rows; everything else comes back empty. */
function mockQueries(rows: Row[]): void {
  (pool.query as ReturnType<typeof vi.fn>).mockImplementation((sql: string) => {
    if (typeof sql === 'string' && sql.includes('JOIN essentials.districts d ON d.geo_id = gb.geo_id')) {
      return Promise.resolve({ rows });
    }
    return Promise.resolve({ rows: [] });
  });
}

describe('a vacant seat returned by address search', () => {
  beforeEach(() => {
    (pool.query as ReturnType<typeof vi.fn>).mockReset();
  });

  it('carries a null id rather than pretending to be a person', async () => {
    mockQueries([VACANT]);
    const { politicians } = await getRepresentativesByCoordinate(34.4, -118.5);
    expect(politicians).toHaveLength(1);
    expect(politicians[0].id).toBeNull();
    expect(politicians[0].full_name).toBe('');
  });

  it('is keyable: every row carries its office_id, which is the only key a vacancy has', async () => {
    mockQueries([HELD, VACANT]);
    const { politicians } = await getRepresentativesByCoordinate(34.4, -118.5);
    expect(politicians.map((p) => p.office_id)).toEqual(['office-held', 'office-vacant']);
  });

  it('says so in seat_status, so a renderer never has to infer it from an empty name', async () => {
    mockQueries([HELD, VACANT]);
    const { politicians } = await getRepresentativesByCoordinate(34.4, -118.5);
    expect(politicians.map((p) => p.seat_status)).toEqual(['held', 'vacant']);
  });

  it('🔴 reads seat_status from the HOLDER, not from is_vacant — a flagged seat with a holder is held', async () => {
    // This is the guard that stops `seat_status: row.is_vacant ? 'vacant' : 'held'`. Those are
    // different questions: is_vacant is an assertion on the office, and CLAUDE.md's "is_vacant
    // trap" documents offices that carry it while a current term exists.
    mockQueries([FLAGGED_BUT_HELD]);
    const { politicians } = await getRepresentativesByCoordinate(34.4, -118.5);
    expect(politicians[0].seat_status).toBe('held');
    // And the flag itself is still reported, unchanged — the two fields answer different things.
    expect(politicians[0].is_vacant).toBe(true);
    expect(politicians[0].vacant_since).toBe('2026-01-15');
  });

  it('keeps the vacancy in the response, with the office and the date a voter needs', async () => {
    mockQueries([VACANT]);
    const { politicians } = await getRepresentativesByCoordinate(34.4, -118.5);
    expect(politicians[0].office_title).toBe('Council Member (District 2)');
    expect(politicians[0].government_name).toBe('City of Testville, Testland, US');
    expect(politicians[0].is_vacant).toBe(true);
    expect(politicians[0].vacant_since).toBe('2025-11-01');
  });

  it('asks for no images or committees for a seat with no person', async () => {
    mockQueries([VACANT]);
    const { politicians } = await getRepresentativesByCoordinate(34.4, -118.5);
    expect(politicians[0].images).toEqual([]);
    expect(politicians[0].committees).toEqual([]);
    // A null id must never reach `politician_id = ANY($1)`.
    const calls = (pool.query as ReturnType<typeof vi.fn>).mock.calls as Array<[string, unknown[]?]>;
    const idArrays = calls
      .filter(([sql]) => typeof sql === 'string'
        && (sql.includes('politician_images') || sql.includes('legislative_committee_memberships')))
      .flatMap(([, params]) => (params?.[0] as unknown[]) ?? []);
    expect(idArrays).not.toContain(null);
  });
});
