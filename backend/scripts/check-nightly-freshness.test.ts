import { describe, it, expect } from 'vitest';

import { judgeFreshness, MAX_AGE_HOURS } from './check-nightly-freshness.mjs';

/**
 * 🔴 WHAT THIS IS GUARDING. Every live-DB tripwire in ci.yml runs ONLY on the
 * schedule. If the schedule stops, none of them go red — they stop running, and
 * a tripwire that is not running is indistinguishable from a tripwire with
 * nothing to report. This check is the one thing that would notice, so the
 * failure mode that matters is a FALSE GREEN: it reading "fresh" while the
 * nightly has in fact stopped.
 *
 * ⚠ The other half of that is a check nobody trusts. It is deliberately NOT red
 * on ordinary drift — measured 2026-11-25, consecutive scheduled runs are 24.0h
 * apart at the median and 32.9h apart at the worst — because a check that fires
 * on ordinary use gets muted, and a muted check is a false green with extra
 * steps. Hence 40h, and hence the two cases below that assert SILENCE.
 */

const now = new Date('2026-11-25T12:00:00Z');
const hoursAgo = (h: number) => new Date(now.getTime() - h * 3_600_000).toISOString();

describe('judgeFreshness', () => {
  it('is silent on a run from this morning', () => {
    expect(judgeFreshness(hoursAgo(5), now).red).toBe(false);
  });

  /**
   * 🔴 THE WORST GAP ACTUALLY OBSERVED MUST NOT FIRE. 32.9h, on 2026-08-27 —
   * ordinary drift crossing a midnight, not a missed day. If this case went red
   * the check would have cried wolf once already in the window it was built
   * from, and would be muted by the time it mattered.
   */
  it('is silent at the worst gap ever measured (32.9h)', () => {
    expect(judgeFreshness(hoursAgo(32.9), now).red).toBe(false);
  });

  it('fires once the nightly has been quiet for longer than the limit', () => {
    const v = judgeFreshness(hoursAgo(41), now);
    expect(v.red).toBe(true);
    expect(v.reason).toContain('41.0h');
  });

  /**
   * ⚠ THE BOUNDARY IS EXCLUSIVE, PINNED SO IT CANNOT DRIFT INTO `>=` BY TIDYING.
   * Exactly 40h is the limit, not past it.
   */
  it('treats exactly the limit as fresh, and a minute past it as stale', () => {
    expect(judgeFreshness(hoursAgo(MAX_AGE_HOURS), now).red).toBe(false);
    expect(judgeFreshness(hoursAgo(MAX_AGE_HOURS + 1 / 60), now).red).toBe(true);
  });

  /**
   * 🔴 NO SCHEDULED RUN AT ALL IS THE WORST CASE, NOT THE QUIET ONE. An empty
   * list means the schedule has never fired or has aged out of retention
   * entirely. Reading it as "nothing to report" would make the check silent in
   * exactly the situation it exists for.
   */
  it('fires when the API returns no scheduled run at all', () => {
    const v = judgeFreshness(null, now);
    expect(v.red).toBe(true);
    expect(v.ageHours).toBeNull();
    expect(v.reason).toContain('no scheduled run');
  });

  it('fires on a timestamp it cannot read, rather than passing it through', () => {
    const v = judgeFreshness('not a date', now);
    expect(v.red).toBe(true);
    expect(v.ageHours).toBeNull();
  });

  /**
   * ⚠ CLOCK SKEW IS NOT A FAILURE. The runner's clock and GitHub's can disagree
   * by seconds, so a just-started run can look like it began in the future.
   * "The nightly ran too recently" is not something anybody can act on.
   */
  it('does not fire on a future timestamp from clock skew', () => {
    expect(judgeFreshness(hoursAgo(-0.1), now).red).toBe(false);
  });

  it('reports the age it measured, so the log carries the trend', () => {
    expect(judgeFreshness(hoursAgo(26), now).ageHours).toBeCloseTo(26, 5);
  });
});
