import { vi, describe, it, expect } from 'vitest';

// Mock DB and geocoding so module-level side effects don't crash the test runner.
vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }));
vi.mock('./geocodingService.js', () => ({ geocodeAddress: vi.fn(), GeocodingError: class GeocodingError extends Error {} }));

import { pickCountyFromDistrictRows } from './essentialsService.js';

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
