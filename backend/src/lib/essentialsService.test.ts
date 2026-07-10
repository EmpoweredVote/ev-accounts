import { vi, describe, it, expect } from 'vitest';

// Mock DB and geocoding so module-level side effects don't crash the test runner.
vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }));
vi.mock('./geocodingService.js', () => ({ geocodeAddress: vi.fn(), GeocodingError: class GeocodingError extends Error {} }));

import { pickCountyFromDistrictRows, pickJurisdictionFromDistrictRows } from './essentialsService.js';

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
