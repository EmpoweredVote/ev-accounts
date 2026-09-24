import { describe, it, expect } from 'vitest';

// Import-safe: main() only auto-runs when import.meta.url matches process.argv[1]
// (the isMainModule guard at the bottom of the loader), which never holds under vitest.
import { refreshNotice } from '../scripts/load-state-tiger-boundaries.js';
import type { RefreshOutcome } from '../scripts/load-state-tiger-boundaries.js';

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
