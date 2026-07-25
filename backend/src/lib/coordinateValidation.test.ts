import { describe, it, expect } from 'vitest';
import { classifyCoordinate, US_BBOX } from './coordinateValidation.js';

describe('classifyCoordinate', () => {
  it('accepts a continental US point (Minneapolis, MN)', () => {
    expect(classifyCoordinate(45.0, -93.0)).toEqual({ ok: true });
  });

  it('accepts Honolulu, HI', () => {
    expect(classifyCoordinate(21.3, -157.8)).toEqual({ ok: true });
  });

  it('accepts Fairbanks, AK', () => {
    expect(classifyCoordinate(64.8, -147.7)).toEqual({ ok: true });
  });

  it('accepts Attu Island, Aleutians (positive longitude crossing the antimeridian)', () => {
    expect(classifyCoordinate(52.9, 173.1)).toEqual({ ok: true });
  });

  it('accepts San Juan, PR', () => {
    expect(classifyCoordinate(18.2, -66.5)).toEqual({ ok: true });
  });

  it('accepts Washington, DC', () => {
    expect(classifyCoordinate(38.9, -77.0)).toEqual({ ok: true });
  });

  it('rejects a valid coordinate outside the US box (London) as OUTSIDE_US_BOUNDS', () => {
    expect(classifyCoordinate(51.5, -0.12)).toEqual({ ok: false, code: 'OUTSIDE_US_BOUNDS' });
  });

  it('rejects a swapped Minneapolis coordinate as SWAPPED_COORDINATES, NOT INVALID_COORDINATES', () => {
    // (lat, lng) = (-93.0, 45.0) is out of the US box, but (lng, lat) = (45.0, -93.0) is
    // the real Minneapolis point — this proves the malformed guard does not shadow the
    // swap branch, even though the "latitude" slot (-93.0) exceeds the +/-90 range.
    const result = classifyCoordinate(-93.0, 45.0);
    expect(result).toEqual({ ok: false, code: 'SWAPPED_COORDINATES' });
    expect(result).not.toEqual({ ok: false, code: 'INVALID_COORDINATES' });
  });

  it('rejects NaN latitude as INVALID_COORDINATES', () => {
    expect(classifyCoordinate(NaN, -93.0)).toEqual({ ok: false, code: 'INVALID_COORDINATES' });
  });

  it('rejects absurd-magnitude input as INVALID_COORDINATES', () => {
    expect(classifyCoordinate(200, 5000)).toEqual({ ok: false, code: 'INVALID_COORDINATES' });
  });

  it('rejects non-finite input (Infinity) as INVALID_COORDINATES', () => {
    expect(classifyCoordinate(Infinity, -93.0)).toEqual({ ok: false, code: 'INVALID_COORDINATES' });
    expect(classifyCoordinate(45.0, -Infinity)).toEqual({ ok: false, code: 'INVALID_COORDINATES' });
  });
});

describe('US_BBOX', () => {
  it('exports a generous US envelope covering continental US through Alaska latitude', () => {
    expect(US_BBOX.lat.min).toBeLessThanOrEqual(17.5);
    expect(US_BBOX.lat.max).toBeGreaterThanOrEqual(72.0);
  });
});
