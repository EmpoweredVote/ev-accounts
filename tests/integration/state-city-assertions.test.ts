import { describe, it, expect } from 'vitest';
import { STATE_CITY_ASSERTIONS } from '../../backend/scripts/load-state-tiger-boundaries.js';

describe('STATE_CITY_ASSERTIONS gate — UT place layer', () => {
  it('UT registry lists exactly the 5 HB 356 cities (D-03)', () => {
    expect(STATE_CITY_ASSERTIONS['UT']).toEqual(
      ['Magna', 'Kearns', 'Copperton', 'Emigration Canyon', 'White City']
    );
  });

  it('gate passes when all 5 cities present (case-insensitive substring)', () => {
    const seenNamelsad = new Set([
      'Magna city', 'Kearns city', 'Copperton city',
      'Emigration Canyon city', 'White City city',
      'Salt Lake City city',
    ]);
    const required = STATE_CITY_ASSERTIONS['UT'];
    const missing = required.filter(
      (city) => !Array.from(seenNamelsad).some(
        (n) => n.toLowerCase().includes(city.toLowerCase())
      )
    );
    expect(missing).toEqual([]);
  });

  it('gate fails when one city is missing and produces the correct missing list', () => {
    const seenNamelsad = new Set([
      'Kearns city', 'Copperton city',
      'Emigration Canyon city', 'White City city',
    ]); // Magna absent
    const required = STATE_CITY_ASSERTIONS['UT'];
    const missing = required.filter(
      (city) => !Array.from(seenNamelsad).some(
        (n) => n.toLowerCase().includes(city.toLowerCase())
      )
    );
    expect(missing).toEqual(['Magna']);
  });
});
