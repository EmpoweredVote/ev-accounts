import { describe, it, expect } from 'vitest';
import { skipReasonFor, DRAFT_THROTTLE_LIMIT } from './pipelineCron.js';

/**
 * WHY THIS EXISTS
 * ---------------
 * `climate-agreements` was retired on 2026-09-10 by setting `is_active = false`.
 * On 2026-09-12 the nightly cron generated ten more questions into it
 * (generation_jobs id=283), because preflight resolves each registered
 * collection by slug, selects only its `id`, and never looks at `is_active`.
 * Retiring a collection hid it from players and did nothing to stop the spend.
 *
 * Lane routing (#452) removed that particular collection from the registry, so
 * the specific leak is closed — but not the defect. `laneTargets.ts` has no
 * `is_active` reference either, so switching off `war-in-iran` today would
 * repeat the whole thing at a new address. The database is still not
 * authoritative over whether a collection generates.
 *
 * The decision is pulled out of the preflight loop so it can be tested without
 * a database. The loop keeps its queries; it just no longer owns the judgement.
 */
describe('skipReasonFor', () => {
  const eligible = { isActive: true, draftCount: 0, draftLimit: DRAFT_THROTTLE_LIMIT };

  it('skips a lane whose collection has been switched off', () => {
    const reason = skipReasonFor({ ...eligible, isActive: false });
    expect(reason).not.toBeNull();
    expect(reason).toContain('is_active');
  });

  it('lets an active collection under the draft limit proceed', () => {
    expect(skipReasonFor(eligible)).toBeNull();
  });

  it('throttles an active collection over the draft limit', () => {
    const reason = skipReasonFor({ ...eligible, draftCount: 21, draftLimit: 20 });
    // Wording preserved verbatim: it is persisted to generation_jobs.reason and
    // read by humans asking why a night produced nothing.
    expect(reason).toBe('auto-throttle: 21 pending review questions exceeds limit of 20');
  });

  it('does not throttle exactly at the limit', () => {
    // The original guard was `draftCount > LIMIT`, not `>=`. Preserved.
    expect(skipReasonFor({ ...eligible, draftCount: 20, draftLimit: 20 })).toBeNull();
  });

  it('reports inactive rather than throttled when both apply', () => {
    // A switched-off collection must never report a throttle reason — a
    // throttle means "come back tomorrow", which is wrong for a retirement.
    const reason = skipReasonFor({ isActive: false, draftCount: 99, draftLimit: 20 });
    expect(reason).toContain('is_active');
    expect(reason).not.toContain('auto-throttle');
  });
});
