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

  // Sub-county seats (commissioner precincts, supervisor and council districts) are typed COUNTY too,
  // with geo_ids of their own, and the point query returns rows in politician-id order — so "the first
  // COUNTY row" is whichever seat's holder sorts first. Measured live 2026-09-23 via coordinate-lookup:
  // Ramsey MN reported county "ramsey-mn-commissioner-district-1", Miami-Dade
  // "miami-dade-fl-commissioner-district-11", Racine "55101-sup-d8". Only a county-wide row carries the
  // county's 5-digit FIPS as its geo_id (all 3,260 such COUNTY districts have a G4020 geofence; no
  // sub-county COUNTY district does).
  it('prefers the county-wide COUNTY row over a sub-county seat that sorts first', () => {
    const rows = [
      { mtfcc: 'X0055', district_type: 'COUNTY', geo_id: 'ramsey-mn-commissioner-district-1', name: 'Ramsey County Commissioner District 1' },
      { mtfcc: 'G4020', district_type: 'COUNTY', geo_id: '27123', name: 'Ramsey County' },
    ];
    expect(pickCountyFromDistrictRows(rows)).toEqual({ geoid: '27123', name: 'Ramsey County' });
  });

  it('falls back to a G4020 court row when the only COUNTY rows are sub-county seats', () => {
    const rows = [
      { mtfcc: 'X0019', district_type: 'COUNTY', geo_id: 'pima-az-supervisor-district-1', name: 'Pima County Supervisor District 1' },
      { mtfcc: 'G4020', district_type: 'JUDICIAL', geo_id: '04019', district_label: 'Pima County Superior Court', name: 'Pima County' },
    ];
    expect(pickCountyFromDistrictRows(rows)).toEqual({ geoid: '04019', name: 'Pima County' });
  });

  it('returns null rather than a sub-county seat when no county-wide row is present', () => {
    const rows = [
      { mtfcc: 'X0060', district_type: 'COUNTY', geo_id: 'richland-sc-council-district-5', name: 'Richland County Council District 5' },
    ];
    expect(pickCountyFromDistrictRows(rows)).toBeNull();
  });

  // X0001 is a synthetic mtfcc shared by both SLCo council districts and SLC ward boundaries
  // (distinguished only by district_type — see boundary-motif-resolution notes). A COUNTY row on an
  // X0001 council-district geofence is a seat, not the county: its geo_id is not a county FIPS and its
  // geofence name is a district label. (Until the county-wide rule above, this returned the council
  // district as the county; the test used to pin that as a characterization of known-wrong behavior.)
  it('does not report an X0001 council-district geofence as the county', () => {
    const rows = [
      {
        mtfcc: 'X0001',
        district_type: 'COUNTY',
        geo_id: 'X0001',
        district_label: 'Salt Lake County',
        name: 'Salt Lake County Council District 5',
      },
    ];
    expect(pickCountyFromDistrictRows(rows)).toBeNull();
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

  it('skips a sub-county COUNTY seat that sorts first (same defect as pickCountyFromDistrictRows)', () => {
    const rows = [
      { district_type: 'COUNTY', geo_id: 'miami-dade-fl-commissioner-district-11' },
      { district_type: 'COUNTY', geo_id: '12086' },
    ];
    expect(pickJurisdictionFromDistrictRows(rows).county).toBe('12086');
  });

  it('county is null when only sub-county seats and a non-county court cover the point', () => {
    const rows = [
      { district_type: 'COUNTY', geo_id: 'travis-tx-commissioner-precinct-4' },
      { district_type: 'JUDICIAL', geo_id: '06-appellate-district-2' },
    ];
    expect(pickJurisdictionFromDistrictRows(rows).county).toBeNull();
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
