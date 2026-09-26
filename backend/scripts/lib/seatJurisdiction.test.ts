import { describe, it, expect } from 'vitest';
import { USPS_TO_STATE_NAME, seatJurisdictionNames } from './seatJurisdiction.js';
import { USPS_TO_FIPS } from './state-fips.mjs';

describe('USPS_TO_STATE_NAME', () => {
  it('covers exactly the jurisdictions in state-fips.mjs (drift guard)', () => {
    expect(Object.keys(USPS_TO_STATE_NAME).map((k) => k.toLowerCase()).sort()).toEqual(Object.keys(USPS_TO_FIPS).sort());
  });
});

describe('seatJurisdictionNames', () => {
  it('maps a USPS code to the full state name and keeps the city', () =>
    expect(seatJurisdictionNames('UT', 'Salt Lake City')).toEqual(['Utah', 'Salt Lake City']));
  it('maps a lowercase code', () => expect(seatJurisdictionNames('in', null)).toEqual(['Indiana']));
  it('keeps a full state name as given', () => expect(seatJurisdictionNames('Utah', null)).toEqual(['Utah']));
  it('drops an unknown two-letter code instead of keeping it', () => expect(seatJurisdictionNames('ZZ', null)).toEqual([]));
  it('drops empty and short tokens', () => expect(seatJurisdictionNames('', 'X')).toEqual([]));
});
