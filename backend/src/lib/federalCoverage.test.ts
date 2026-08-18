import { vi, describe, it, expect } from 'vitest';

// federalCoverage.ts imports db.js at module scope; db.js's env validation calls
// process.exit(1) in a test env with no DB vars. Only the pure exports are under
// test here — mock the pool away (essentialsService.test.ts convention).
vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }));

import { ALL_STATES, federalStateScore } from './federalCoverage.js';

describe('ALL_STATES', () => {
  it('covers all 56 postal jurisdictions with unique codes and fips', () => {
    expect(ALL_STATES).toHaveLength(56);
    expect(new Set(ALL_STATES.map((s) => s.code)).size).toBe(56);
    expect(new Set(ALL_STATES.map((s) => s.fips)).size).toBe(56);
  });

  it('has exactly 100 voting Senate seats (50 states × 2, none for DC/territories)', () => {
    expect(ALL_STATES.reduce((sum, s) => sum + s.senateSeats, 0)).toBe(100);
    for (const code of ['dc', 'pr', 'gu', 'vi', 'as', 'mp']) {
      expect(ALL_STATES.find((s) => s.code === code)?.senateSeats).toBe(0);
    }
  });

  it('expects a governor everywhere except DC (mayor)', () => {
    expect(ALL_STATES.find((s) => s.code === 'dc')?.governorSeats).toBe(0);
    expect(ALL_STATES.filter((s) => s.governorSeats === 1)).toHaveLength(55);
  });
});

describe('federalStateScore', () => {
  const full = {
    senateFilled: 2, senateExpected: 2,
    houseCovered: 8, houseExpected: 8,
    governorFilled: 1, governorExpected: 1,
    delegationResearched: 11, delegationTotal: 11,
    delegationWithPhoto: 11,
    stateLegCovered: 0, stateLegTotal: 0,
  };

  it('is 100 when every applicable axis is full', () => {
    expect(federalStateScore(full)).toBe(100);
  });

  it('is 0 when no axis applies', () => {
    expect(
      federalStateScore({
        senateFilled: 0, senateExpected: 0,
        houseCovered: 0, houseExpected: 0,
        governorFilled: 0, governorExpected: 0,
        delegationResearched: 0, delegationTotal: 0,
        delegationWithPhoto: 0,
        stateLegCovered: 0, stateLegTotal: 0,
      }),
    ).toBe(0);
  });

  it('drops the Senate axis for DC/territories instead of scoring it 0', () => {
    // DC: delegate seat filled + researched + photographed, no senate/governor.
    const dc = federalStateScore({
      senateFilled: 0, senateExpected: 0,
      houseCovered: 1, houseExpected: 1,
      governorFilled: 0, governorExpected: 0,
      delegationResearched: 1, delegationTotal: 1,
      delegationWithPhoto: 1,
      stateLegCovered: 0, stateLegTotal: 0,
    });
    expect(dc).toBe(100);
  });

  it('drops the legislature axis when no legislative districts are loaded', () => {
    const withUnknownLeg = federalStateScore(full);
    const withEmptyLeg = federalStateScore({ ...full, stateLegCovered: 0, stateLegTotal: 100 });
    expect(withUnknownLeg).toBe(100); // axis dropped — not penalised
    expect(withEmptyLeg).toBeLessThan(100); // axis present and empty — penalised
  });

  it('never exceeds 1 per axis on over-filled seats (data errors)', () => {
    expect(federalStateScore({ ...full, senateFilled: 3 })).toBe(100);
  });

  it('weights roster above research depth', () => {
    const noStances = federalStateScore({ ...full, delegationResearched: 0 });
    const noHouse = federalStateScore({ ...full, houseCovered: 0 });
    expect(noStances).toBeGreaterThan(noHouse);
  });
});
