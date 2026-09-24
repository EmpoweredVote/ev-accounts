import { describe, it, expect } from 'vitest';

// ⚠⚠ THIS FILE LIVES IN scripts/ ON PURPOSE. CI's backend job runs `npm run test:unit`, which is
//    `vitest run src scripts` — a test under test/ is never executed by it. Written there first,
//    these ten passed locally and would have run NOWHERE in CI, which is the same class of defect
//    as the message nobody read that this whole change is about.

// Import-safe: main() only auto-runs when import.meta.url matches process.argv[1]
// (the isMainModule guard at the bottom of the loader), which never holds under vitest.
import { refreshNotice } from './load-state-tiger-boundaries.js';
import type { RefreshOutcome } from './load-state-tiger-boundaries.js';

/**
 * 🔴 WHAT THESE PIN IS THE QUIET FAILURE, NOT THE HAPPY PATH.
 *
 * The loader now refreshes essentials.geofence_child_county itself, through a
 * SECURITY DEFINER function, because it connects as `ev_api` and `ev_api` cannot
 * refresh a matview owned by postgres (measured: "permission denied for
 * materialized view"). Every way that call can go wrong — the migration not
 * applied, the grant revoked, the function renamed — ends in a catch. If the
 * catch prints something reassuring, the operator walks away believing the
 * mapping is current and the coverage dashboard silently shows jurisdictions
 * with no county, which is the exact condition that ran red for six nights
 * (2026-09-18..23) and the whole reason this call exists.
 *
 * So: a failure must be louder than a success, and must never contain the word
 * that makes a reader stop reading.
 */

const lines = (o: RefreshOutcome, inserted = 5155) => refreshNotice(o, inserted).join('\n');

describe('refreshNotice — the refresh worked', () => {
  it('reports the before and after counts, so "done" is falsifiable', () => {
    const out = lines({ kind: 'refreshed', staleBefore: 5155, staleAfter: 0 });
    expect(out).toMatch(/5155/);
    expect(out).toMatch(/\b0\b/);
  });

  it('asks the operator for nothing — no manual SQL, no ACTION REQUIRED', () => {
    const out = lines({ kind: 'refreshed', staleBefore: 5155, staleAfter: 0 });
    expect(out).not.toMatch(/ACTION REQUIRED/i);
    expect(out).not.toMatch(/REFRESH MATERIALIZED VIEW/);
  });
});

describe('refreshNotice — the refresh ran but did not clear the backlog', () => {
  // A refresh that leaves rows stale is not a success with a caveat: the matview
  // now matches the boundaries table and rows are STILL unmapped, which means the
  // cause is something other than staleness. Reporting it as done hides that.
  it('is reported as a problem, not as a success', () => {
    const out = lines({ kind: 'refreshed', staleBefore: 5155, staleAfter: 12 });
    expect(out).toMatch(/ACTION REQUIRED|⚠/);
    expect(out).toMatch(/12/);
  });

  it('does not claim the mapping is current', () => {
    const out = lines({ kind: 'refreshed', staleBefore: 5155, staleAfter: 12 });
    expect(out).not.toMatch(/up to date|current\b/i);
  });
});

describe('refreshNotice — the call failed', () => {
  it('names the reason rather than swallowing it', () => {
    const out = lines({ kind: 'failed', reason: 'function essentials.refresh_geofence_child_county() does not exist' });
    expect(out).toMatch(/does not exist/);
  });

  it('gives the operator the manual command to run', () => {
    const out = lines({ kind: 'failed', reason: 'permission denied' });
    expect(out).toMatch(/REFRESH MATERIALIZED VIEW CONCURRENTLY essentials\.geofence_child_county;/);
    expect(out).toMatch(/check:child-county/);
  });

  it('🔴 never reads as a success', () => {
    const out = lines({ kind: 'failed', reason: 'permission denied' });
    expect(out).toMatch(/NOT refreshed|ACTION REQUIRED/);
    expect(out).not.toMatch(/mapping refreshed/i);
  });
});

describe('refreshNotice — what it tells you about CI', () => {
  // The job has been schedule-only since 2026-08-26. The old message said CI ran
  // this "on every push", which overstates how fast anyone would find out.
  it('does not claim CI checks this on every push', () => {
    const out = lines({ kind: 'failed', reason: 'permission denied' });
    expect(out).not.toMatch(/every push/i);
    expect(out).toMatch(/nightly/i);
  });
});

describe('refreshNotice — the manual fallback tells the truth about the statement', () => {
  // Both claims below were wrong in the message this replaced, and both mislead in a way that
  // costs time at exactly the wrong moment — standing in front of a stale matview.
  const out = () => refreshNotice({ kind: 'failed', reason: 'permission denied' }, 5155).join('\n');

  it('does not repeat the "cannot run in a transaction" claim', () => {
    // Measured 2026-09-24: REFRESH ... CONCURRENTLY ran fine inside a plpgsql block. The
    // restriction belongs to CREATE INDEX CONCURRENTLY.
    expect(out()).not.toMatch(/not in a transaction|cannot run inside a transaction/i);
  });

  it('quotes a duration that matches what the refresh actually takes', () => {
    // Measured 2026-09-24 against prod: 30,797 ms. The old "~17 s" is from migration 1696 and is
    // what makes ev_api's 30 s statement_timeout look like plenty of headroom. It is not.
    expect(out()).not.toMatch(/~17 s/);
    expect(out()).toMatch(/~3[01] s|~31 s/);
  });
});
