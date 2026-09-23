import { vi, describe, it, expect } from 'vitest';

// Mock DB and geocoding so module-level side effects don't crash the test runner.
vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }));
vi.mock('./geocodingService.js', () => ({ geocodeAddress: vi.fn(), GeocodingError: class GeocodingError extends Error {} }));

import { pool } from './db.js';
import { getPoliticiansFlatList, pickCountyFromDistrictRows, pickJurisdictionFromDistrictRows } from './essentialsService.js';

describe('pickCountyFromDistrictRows', () => {
  it('returns geoid + name from the G4020 row', () => {
    const rows = [
      { mtfcc: 'G5220', district_type: 'STATE_LOWER', geo_id: '49021', district_label: 'House District 21' },
      { mtfcc: 'G4020', district_type: 'COUNTY', geo_id: '49035', district_label: 'Salt Lake County' },
    ];
    expect(pickCountyFromDistrictRows(rows)).toEqual({ geoid: '49035', name: 'Salt Lake County' });
  });

  it('matches a COUNTY district_type even if mtfcc is non-standard', () => {
    const rows = [{ mtfcc: 'X0001', district_type: 'COUNTY', geo_id: '49035', district_label: 'Salt Lake County' }];
    expect(pickCountyFromDistrictRows(rows)).toEqual({ geoid: '49035', name: 'Salt Lake County' });
  });

  it('returns null when no county row is present', () => {
    const rows = [{ mtfcc: 'G5220', district_type: 'STATE_LOWER', geo_id: '49021', district_label: 'House District 21' }];
    expect(pickCountyFromDistrictRows(rows)).toBeNull();
  });

  it('returns null when the county row has no geo_id', () => {
    const rows = [{ mtfcc: 'G4020', district_type: 'COUNTY', geo_id: '', district_label: 'Salt Lake County' }];
    expect(pickCountyFromDistrictRows(rows)).toBeNull();
  });

  it('prefers the COUNTY row over a G4020 court row sharing the geoid', () => {
    const rows = [
      { mtfcc: 'G4020', district_type: 'JUDICIAL', geo_id: '49035', district_label: 'Third District Court' },
      { mtfcc: 'G4020', district_type: 'COUNTY', geo_id: '49035', district_label: 'Salt Lake County' },
    ];
    expect(pickCountyFromDistrictRows(rows)).toEqual({ geoid: '49035', name: 'Salt Lake County' });
  });

  it('prefers the geofence name over district_label, which is a seat label ("At-Large") not the county name', () => {
    const rows = [
      { mtfcc: 'G4020', district_type: 'COUNTY', geo_id: '18105', district_label: 'At-Large', name: 'Monroe County' },
    ];
    expect(pickCountyFromDistrictRows(rows)).toEqual({ geoid: '18105', name: 'Monroe County' });
  });

  it('falls back to district_label when the geofence name is absent', () => {
    const rows = [
      { mtfcc: 'G4020', district_type: 'COUNTY', geo_id: '49035', district_label: 'Salt Lake County' },
    ];
    expect(pickCountyFromDistrictRows(rows)).toEqual({ geoid: '49035', name: 'Salt Lake County' });
  });

  // NOTE: characterization test, not a spec. X0001 is a synthetic mtfcc shared by
  // both SLCo council districts and SLC ward boundaries (distinguished only by
  // district_type — see boundary-motif-resolution notes). When a COUNTY-typed
  // district row's matched geofence happens to be an X0001 council-district
  // polygon, that geofence's `name` is a district-specific label (e.g. "...
  // Council District 5"), not the plain county name. pickCountyFromDistrictRows
  // has no mtfcc-based guard against this — it takes district_type === 'COUNTY'
  // as sufficient and trusts `name` unconditionally. This test documents that
  // CURRENT (arguably wrong) behavior: the resolved name is the council
  // boundary's label, not "Salt Lake County". Flagging for a future fix rather
  // than changing production behavior here.
  it('NOTE: returns the X0001 council-district name, not the plain county name, when a COUNTY row resolves to a council-district geofence', () => {
    const rows = [
      {
        mtfcc: 'X0001',
        district_type: 'COUNTY',
        geo_id: 'X0001',
        district_label: 'Salt Lake County',
        name: 'Salt Lake County Council District 5',
      },
    ];
    expect(pickCountyFromDistrictRows(rows)).toEqual({
      geoid: 'X0001',
      name: 'Salt Lake County Council District 5',
    });
  });
});

describe('pickJurisdictionFromDistrictRows', () => {
  it('extracts each jurisdiction field from its matching district_type row', () => {
    const rows = [
      { district_type: 'NATIONAL_LOWER', geo_id: '1809' },
      { district_type: 'STATE_UPPER', geo_id: '1840' },
      { district_type: 'STATE_LOWER', geo_id: '1862' },
      { district_type: 'COUNTY', geo_id: '18105' },
      { district_type: 'SCHOOL', geo_id: '1802220' },
    ];
    expect(pickJurisdictionFromDistrictRows(rows)).toEqual({
      congressional: '1809',
      state_senate: '1840',
      state_house: '1862',
      county: '18105',
      school_district: '1802220',
    });
  });

  it('returns null for each field with no matching row', () => {
    expect(pickJurisdictionFromDistrictRows([])).toEqual({
      congressional: null,
      state_senate: null,
      state_house: null,
      county: null,
      school_district: null,
    });
  });

  it('falls back to a JUDICIAL row for county when no COUNTY row is present', () => {
    const rows = [{ district_type: 'JUDICIAL', geo_id: '18105' }];
    expect(pickJurisdictionFromDistrictRows(rows).county).toBe('18105');
  });

  it('prefers a COUNTY row over a JUDICIAL row sharing the geoid', () => {
    const rows = [
      { district_type: 'JUDICIAL', geo_id: '18105' },
      { district_type: 'COUNTY', geo_id: '18105' },
    ];
    expect(pickJurisdictionFromDistrictRows(rows).county).toBe('18105');
  });
});

describe('getPoliticiansFlatList incumbents-only filter', () => {
  // is_incumbent defaulted to true until CA_0188, so the flag alone admitted 1,817 active rows
  // that hold no office. Only office_terms (through office_current_holder) can say who holds a seat.
  async function sqlFor(includeCandidates: boolean): Promise<string> {
    const query = vi.mocked(pool.query);
    query.mockReset();
    query.mockResolvedValue({ rows: [] } as never);
    await getPoliticiansFlatList(includeCandidates);
    return String(query.mock.calls[0][0]);
  }

  it('requires a current seat when candidates are excluded', async () => {
    const sql = await sqlFor(false);
    expect(sql).toContain('och.office_id IS NOT NULL');
    expect(sql).toContain('p.is_incumbent = true');
  });

  it('does not require a seat when candidates are included', async () => {
    const sql = await sqlFor(true);
    expect(sql).not.toContain('och.office_id IS NOT NULL');
    expect(sql).not.toContain('p.is_incumbent = true');
  });
});
