/**
 * The incumbency reconciler — now only `race_candidates.is_incumbent`.
 *
 * `politicians.is_incumbent` was dropped (CA_0378): every read derives incumbency from
 * office_terms via src/lib/incumbency.ts. The last block here keeps it from coming back.
 */
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { findDrift, driftExitCode } from './reconcile-incumbency.mjs';

describe('findDrift', () => {
  // 🔴 These pin rules this script used to have and MUST NOT get back. They were applied
  // to a first measurement that reported 429 drift rows; reading real rows showed only 9 were
  // drift. CC_0342 has the full account.
  it('ignores a cross-office candidate: holding a seat elsewhere is not incumbency in THIS race', () => {
    // A state senator running for the U.S. House. The global rule called 234 rows like this
    // drift and would have relabelled every one as the incumbent of a race they were
    // challenging. The expected value is computed per row by the caller's SQL, against the
    // race's own office on the race's own election date.
    const drift = findDrift({
      raceCandidates: [{ id: 'rc1', politician_id: 'p4', is_incumbent: false, expected_is_incumbent: false }],
    });
    expect(drift).toEqual([]);
  });

  it('flags a candidate defending the very seat they held on election day', () => {
    const drift = findDrift({
      raceCandidates: [{ id: 'rc2', politician_id: 'p6', is_incumbent: false, expected_is_incumbent: true }],
    });
    expect(drift).toEqual([
      { raceCandidateId: 'rc2', politicianId: 'p6', column: 'race_candidates.is_incumbent', current: false, expected: true },
    ]);
  });

  it('does not call a winner seated AFTER the election its incumbent', () => {
    // Chris Jamieson and Brandon Smith hold their seats today but took office weeks after the
    // elections they appear in. They ran as challengers and won; stored false is correct, and a
    // "holds it today" rule would have flipped all three.
    const drift = findDrift({
      raceCandidates: [{ id: 'rc3', politician_id: 'p7', is_incumbent: false, expected_is_incumbent: false }],
    });
    expect(drift).toEqual([]);
  });
});

describe('the race-candidate predicate: seat-scoped, widened to the chamber only for multi-seat races', () => {
  // 🔴 A TEXT GUARD on this module's own SQL (ruling 2026-11-07). A multi-seat race points at ONE
  // of its body's offices, so the seat-only rule called the other sitting members defending a seat
  // in it challengers. The widening must stay behind `r.seats > 1`: without that guard every
  // cross-office candidate in the same chamber would be relabelled an incumbent.
  const src = readFileSync(new URL('./reconcile-incumbency.mjs', import.meta.url), 'utf8');

  it('accepts a seat of the same chamber only when the race fills more than one seat', () => {
    expect(src).toMatch(/r\.seats > 1 AND ro\.chamber_id IS NOT NULL AND o2\.chamber_id = ro\.chamber_id/);
  });

  it("still matches the race's own office for every race", () => {
    expect(src).toMatch(/t\.office_id = r\.office_id\s*\n?\s*OR \(r\.seats > 1/);
  });
});

describe('driftExitCode — what a scheduled --check run does', () => {
  // 🔴 This script RAN NOWHERE until it was scheduled. It was built, tested and controlled while
  // nothing invoked it, so drift would have accumulated silently again — the one thing it exists
  // to stop. These pin the decision the daily job makes.
  it('fails the job when --check finds drift', () => {
    expect(driftExitCode({ check: true, driftCount: 1 })).toBe(1);
  });

  it('passes when --check finds none', () => {
    expect(driftExitCode({ check: true, driftCount: 0 })).toBe(0);
  });

  it('never fails a plain read-only run, however much drift it reports', () => {
    // Running it by hand to LOOK must not be a failure; only the scheduled gate is a gate.
    expect(driftExitCode({ check: false, driftCount: 429 })).toBe(0);
  });
});

describe('nothing in the request path or the live loaders touches the dropped politicians.is_incumbent', () => {
  // A TEXT GUARD. The column was dropped (CA_0378); a read or a write of it is a 42703 at
  // run time. Reads use src/lib/incumbency.ts. race_candidates.is_incumbent (`rc.`) is a different,
  // still-live column, so only the person-table spellings are forbidden here.
  const readers = [
    '../src/lib/districtQueries.ts',
    '../src/lib/essentialsService.ts',
    '../src/lib/essentialsBrowseService.ts',
    '../src/lib/profileService.ts',
    './check-address-reachability.mjs',
  ];
  const strip = (src: string) => src.split('\n').filter((l) => !/^\s*(\/\/|\*|--)/.test(l)).join('\n');
  for (const f of readers) {
    it(`${f} does not read p.is_incumbent`, () => {
      const code = strip(readFileSync(new URL(f, import.meta.url), 'utf8'));
      expect(code).not.toMatch(/\bp\.is_incumbent\b/);
    });
  }

  const writers = [
    '../src/lib/stagingService.ts',
    '../src/lib/adminService.ts',
    './lib/politician-upsert.ts',
  ];
  for (const f of writers) {
    it(`${f} does not name is_incumbent in code`, () => {
      const code = strip(readFileSync(new URL(f, import.meta.url), 'utf8'));
      expect(code).not.toMatch(/\bis_incumbent\b/);
    });
  }

  it('the guard can see a read and a write (positive control)', () => {
    expect(strip('  AND p.is_incumbent = true')).toMatch(/\bp\.is_incumbent\b/);
    expect(strip('  (full_name, is_incumbent)')).toMatch(/\bis_incumbent\b/);
  });
});
