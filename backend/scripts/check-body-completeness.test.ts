import { describe, it, expect } from 'vitest';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  classifyChamber,
  bucketCounts,
  compareToBaseline,
  assertPopulationRead,
} from './check-body-completeness.mjs';

/**
 * The gate's judgement is pure and tested here directly. The SQL that feeds it is
 * exercised by `--selftest`, which plants a tamper in a transaction and watches the
 * gate go red before rolling back.
 *
 * ⚠⚠ WHAT MUST NEVER PASS SILENTLY. `official_count = 0` means "nobody set this",
 * not "this body has no members" — 296 chambers carry it, including Indiana township
 * boards that plainly have three. Read as a size it makes every one of them look like
 * it holds three offices too many. A gate that reports 307 findings when 19 are real
 * is a gate people switch off, so the sentinel is excluded here and counted separately.
 *
 * ⚠⚠ AND AN EMPTY READ MUST NOT COMPARE EQUAL TO A CLEAN ONE. If the query returns no
 * rows — a renamed column, a dropped table, a connection to the wrong database — then
 * "no violations" is indistinguishable from "nothing was examined". The population
 * assertion below is what separates them, and it throws rather than returning clean.
 */

describe('classifyChamber: what counts as a mismatch', () => {
  it('says nothing when the body states no size', () => {
    expect(classifyChamber({ official_count: null, offices: 7 })).toBeNull();
  });

  it('treats official_count = 0 as unset, not as a body with no members', () => {
    // The trap. Indiana township boards carry 0 and hold 3 offices each.
    expect(classifyChamber({ official_count: 0, offices: 3 })).toBeNull();
  });

  it('says nothing when the stated size matches our rows', () => {
    expect(classifyChamber({ official_count: 7, offices: 7 })).toBeNull();
  });

  it('reports too_many when we hold more offices than the body has seats', () => {
    // South Portland's shape: charter says 7, we held 8.
    expect(classifyChamber({ official_count: 7, offices: 8 })).toBe('too_many');
  });

  it('reports too_few when the body has seats we do not hold', () => {
    // Lewiston's shape: charter says 9, we hold 8.
    expect(classifyChamber({ official_count: 9, offices: 8 })).toBe('too_few');
  });
});

describe('bucketCounts: how violations are grouped', () => {
  it('keys a chamber bucket on state and direction, because the two need opposite fixes', () => {
    const rows = [
      { state: 'ME', official_count: 9, offices: 8 },
      { state: 'CA', official_count: 5, offices: 8 },
      { state: 'CA', official_count: 4, offices: 5 },
    ];
    expect(bucketCounts(rows, 'chamber')).toEqual({
      'ca|too_many': 2,
      'me|too_few': 1,
    });
  });

  it('lower-cases the state so ME and me land in one bucket', () => {
    const rows = [
      { state: 'ME', official_count: 9, offices: 8 },
      { state: 'me', official_count: 5, offices: 4 },
    ];
    expect(bucketCounts(rows, 'chamber')).toEqual({ 'me|too_few': 2 });
  });

  it('keys a district bucket on state and district_type', () => {
    const rows = [
      { state: 'ME', district_type: 'COUNTY' },
      { state: 'ME', district_type: 'COUNTY' },
      { state: 'IN', district_type: 'LOCAL' },
    ];
    expect(bucketCounts(rows, 'district')).toEqual({
      'in|LOCAL': 1,
      'me|COUNTY': 2,
    });
  });
});

describe('compareToBaseline: when the gate fires', () => {
  it('stays green when a known bucket is unchanged', () => {
    expect(compareToBaseline({ 'me|COUNTY': 16 }, { 'me|COUNTY': 16 })).toEqual([]);
  });

  it('stays green when a known bucket shrinks', () => {
    expect(compareToBaseline({ 'me|COUNTY': 4 }, { 'me|COUNTY': 16 })).toEqual([]);
  });

  it('fires on growth inside a known bucket', () => {
    expect(compareToBaseline({ 'me|COUNTY': 17 }, { 'me|COUNTY': 16 })).toEqual([
      { bucket: 'me|COUNTY', found: 17, allowed: 16 },
    ]);
  });

  it('fires on any new bucket, however small', () => {
    // This is the half that catches a wave seeding a state nobody baselined.
    expect(compareToBaseline({ 'nh|COUNTY': 1 }, {})).toEqual([
      { bucket: 'nh|COUNTY', found: 1, allowed: 0 },
    ]);
  });

  it('reports every offending bucket, not just the first', () => {
    const found = compareToBaseline(
      { 'me|COUNTY': 17, 'nh|COUNTY': 1 },
      { 'me|COUNTY': 16 },
    );
    expect(found).toHaveLength(2);
  });
});

describe('assertPopulationRead: an empty read is not a clean one', () => {
  it('throws when the query examined nothing', () => {
    expect(() => assertPopulationRead(0, 'chambers')).toThrow(/examined 0 chambers/);
  });

  it('passes when rows were examined', () => {
    expect(() => assertPopulationRead(1462, 'chambers')).not.toThrow();
  });
});

describe('running it with no database', () => {
  const HERE = path.dirname(fileURLToPath(import.meta.url));
  const SCRIPT = path.join(HERE, 'check-body-completeness.mjs');

  it('skips green rather than failing, because forks get no secrets', () => {
    const run = spawnSync(process.execPath, [SCRIPT], {
      encoding: 'utf8',
      env: { ...process.env, DATABASE_URL: '', SKIP_DOTENV: '1' },
    });
    expect(run.status).toBe(0);
    expect(run.stdout).toMatch(/DATABASE_URL/);
  });
});
