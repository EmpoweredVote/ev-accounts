import { describe, it, expect } from 'vitest';
import { progressKey } from './bobitProgressService.js';
import { FEDERAL_SLUG } from '../config/federalCollection.js';

/**
 * WHY THIS EXISTS
 * ---------------
 * `progressKey()` decides what a player's bobits are filed under, and its whole job is to
 * make a session with no collection slug land on the same key on the write path (grantBobit,
 * at answer time) and the read path (readOwnedExternalIds, at session start). It did that
 * faithfully -- onto 'federal-civics', a slug no collection has ever had.
 *
 * WHAT THIS CAN CATCH: a default that stops being the shared constant. Re-inline a literal
 * here, or let the two modules drift apart, and the first test fails.
 *
 * WHAT IT CANNOT: whether `FEDERAL_SLUG` names a row in `trivia.collections`. That is a fact
 * about the database, and no test that runs without one can see it. The original bug lived in
 * exactly that gap for its entire life -- so if this value is ever changed, check it against
 * the database by hand. `SELECT id, slug FROM trivia.collections WHERE slug = '<value>'`
 * returning no row is the bug, and the only place it is visible.
 */
describe('progressKey', () => {
  it('defaults to the same constant the collection lookup resolves by', () => {
    // Not `toBe('federal')`: the point is that one constant feeds both, not what it says today.
    expect(progressKey(null)).toBe(FEDERAL_SLUG);
    expect(progressKey(undefined)).toBe(FEDERAL_SLUG);
  });

  it('passes a real slug through untouched', () => {
    expect(progressKey('washington-dc')).toBe('washington-dc');
    expect(progressKey(FEDERAL_SLUG)).toBe(FEDERAL_SLUG);
  });

  it('does not treat the empty string as missing', () => {
    // `??` only coalesces null and undefined. An empty slug is a bug upstream, and quietly
    // filing it under Federal would hide that by mixing a stranger's bobits into the crowd.
    expect(progressKey('')).toBe('');
  });
});
