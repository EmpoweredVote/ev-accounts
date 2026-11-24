/**
 * geoOverlapStore — the durable, version-invalidated store behind
 * `resolveOverlappingGeoPairs`.
 *
 * Everything that touches `essentials.geo_overlap_pairs` and
 * `essentials.geofence_version` lives here. This module knows nothing about the
 * resolver's SQL: it is *passed* a fingerprint. That keeps the dependency
 * one-way (essentialsBrowseService → geoOverlapStore) and avoids an import
 * cycle, while the SQL text itself stays in essentialsBrowseService.ts where
 * two source-pattern test files read it as text.
 *
 * Design: docs/superpowers/specs/2026-11-24-geo-overlap-precompute-design.md
 */

import { createHash } from 'node:crypto';

/**
 * The identity of the resolver's answer-shaping code, as a short hex digest.
 *
 * 🔴 The input is the resolver's FINISHED SQL text, not a hand-maintained list
 * of constants. All four TypeScript values that change the answer —
 * UNRESOLVABLE_PAIR_MTFCCS, branch 3's seven-MTFCC list, branch 2's
 * ('G4110','G4120') exclusion and MIN_OVERLAP_FRACTION — are already
 * interpolated into, or written literally inside, that string. Hashing the
 * finished text therefore covers all four, and there is no second list that can
 * fall out of step with the first.
 *
 * 16 hex characters of SHA-256: this is a cache key, not a security boundary.
 */
export function fingerprintOf(sql: string): string {
  return createHash('sha256').update(sql, 'utf8').digest('hex').slice(0, 16);
}
