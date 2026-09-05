import { describe, it, expect } from 'vitest';
import {
  LEASE_HOURS, MARKER_HOURS, EXPIRED_GRACE_HOURS, EXPIRY_WARN_HOURS,
  leaseStatus, humanAge, humanAgo,
} from './steward-lease.mjs';

// The design left lease duration open: "Eight hours is a guess. It wants to be longer than a
// working session and shorter than a weekend." Both halves of that were then measured against
// 52 real session transcripts for this project, and the guess was wrong in one direction:
//
//   sessions (>=200 messages, n=47) that outlive a lease of...
//     8h -> 28/47  (60%)      <- the shipped guess expired during most working sessions
//    12h -> 17/47  (36%)      <- the shipped worktree marker
//    16h -> 13/47  (28%)
//    20h ->  4/47   (9%)      <- the overnight cliff
//    24h ->  3/47   (6%)      <- chosen
//    48h ->  0/47   (0%)      <- but no longer "shorter than a weekend"
//
// 🔴 THE TWO FAILURE MODES ARE NOT SYMMETRIC, WHICH IS WHY THE NUMBER ALONE IS NOT THE FIX.
//    A lease that is too LONG fails visibly: the board names the holder and the timestamp, and
//    `--takeover` is one command. A lease that is too SHORT fails SILENTLY — the row simply
//    stops matching, nobody is warned, and two sessions write one jurisdiction. That is the
//    exact class of failure this whole design exists to remove, so the residual 6% is made
//    LOUD rather than tuned away.

describe('the measured constants', () => {
  it('is longer than a working session and shorter than a weekend', () => {
    expect(LEASE_HOURS).toBeGreaterThan(20);   // p90 of measured session span
    expect(LEASE_HOURS).toBeLessThan(48);      // the design's upper bound
  });

  // Two different guesses for the same underlying question is worse than one measurement. Both
  // ask "how long might a session still be around?", and both were measured on the same 52
  // transcripts, so they are the same number.
  it('uses one measurement for the lease and the worktree marker', () => {
    expect(MARKER_HOURS).toBe(LEASE_HOURS);
  });

  it('keeps an expired claim visible long enough for the next session to see it', () => {
    expect(EXPIRED_GRACE_HOURS).toBeGreaterThanOrEqual(12);
  });

  it('warns before expiry, not after', () => {
    expect(EXPIRY_WARN_HOURS).toBeGreaterThan(0);
    expect(EXPIRY_WARN_HOURS).toBeLessThan(LEASE_HOURS);
  });
});

const now = Date.parse('2026-09-04T20:00:00Z');
const at = (h: number) => new Date(now + h * 3.6e6);

describe('leaseStatus', () => {
  it('is live with plenty of time left', () => {
    expect(leaseStatus(at(20), now)).toBe('live');
  });

  // 🔴 THIS IS THE HALF THAT REMOVES THE SILENT FAILURE. A claim about to lapse is announced
  //    while its holder can still act on it — `extend` is one command, but only if you know.
  it('is expiring-soon inside the warning window', () => {
    expect(leaseStatus(at(1), now)).toBe('expiring-soon');
    expect(leaseStatus(at(EXPIRY_WARN_HOURS - 0.01), now)).toBe('expiring-soon');
  });

  it('is recently-expired just after the lease lapses', () => {
    expect(leaseStatus(at(-0.1), now)).toBe('recently-expired');
    expect(leaseStatus(at(-EXPIRED_GRACE_HOURS + 0.01), now)).toBe('recently-expired');
  });

  // Past the grace window it is genuinely free, and saying otherwise would keep a jurisdiction
  // looking occupied forever by a session that ended days ago.
  it('is stale once the grace window has passed', () => {
    expect(leaseStatus(at(-EXPIRED_GRACE_HOURS - 0.01), now)).toBe('stale');
    expect(leaseStatus(at(-72), now)).toBe('stale');
  });

  it('reads an ISO string as readily as a Date, because pg can hand back either', () => {
    expect(leaseStatus('2026-09-05T16:00:00Z', now)).toBe('live');
  });

  it('calls an unreadable timestamp stale rather than guessing it is live', () => {
    expect(leaseStatus(null, now)).toBe('stale');
    expect(leaseStatus('not a date', now)).toBe('stale');
  });

  // The boundary belongs to the live side: a lease expiring at exactly now has not yet lapsed.
  it('puts the exact expiry instant on the expiring side, not the expired side', () => {
    expect(leaseStatus(at(0), now)).toBe('expiring-soon');
  });
});

describe('humanAge', () => {
  it('reads in minutes under an hour', () => {
    expect(humanAge(40 * 60000)).toBe('40m');
    expect(humanAge(59 * 60000)).toBe('59m');
  });

  it('reads in hours and minutes under a day', () => {
    expect(humanAge(3.5 * 3.6e6)).toBe('3h 30m');
    expect(humanAge(3 * 3.6e6)).toBe('3h');
  });

  it('reads in days and hours beyond that', () => {
    expect(humanAge(26 * 3.6e6)).toBe('1d 2h');
    expect(humanAge(48 * 3.6e6)).toBe('2d');
  });

  // "0m ago" is a worse answer than "just now" and a clock skew must not print "-3m".
  it('collapses zero and negative to just now', () => {
    expect(humanAge(0)).toBe('just now');
    expect(humanAge(-5000)).toBe('just now');
    expect(humanAge(20000)).toBe('just now');
  });
});

describe('humanAgo', () => {
  // 🔴 THE REGRESSION THIS PINS WAS VISIBLE ON THE LIVE BOARD: "seen just now ago". Three call
  //    sites each wrote `${humanAge(x)} ago`, and "just now" is the one value that already
  //    carries its own tense. The suffix belongs here, not at the callers.
  it('does not say "just now ago"', () => {
    expect(humanAgo(0)).toBe('just now');
    expect(humanAgo(1000)).toBe('just now');
  });

  it('suffixes every other age', () => {
    expect(humanAgo(40 * 60000)).toBe('40m ago');
    expect(humanAgo(3.5 * 3.6e6)).toBe('3h 30m ago');
    expect(humanAgo(26 * 3.6e6)).toBe('1d 2h ago');
  });
});
