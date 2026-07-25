/**
 * coordinateValidation — pure US-bbox + swap-guard classification for the
 * anonymous coordinate lookup endpoint (Phase 213, RSLV-03).
 *
 * Standalone module: no DB access, no HTTP, no imports from the address
 * lookup or address-resolution service layers. Exhaustively unit-testable
 * in isolation.
 *
 * D-02: US_BBOX is a GENEROUS US envelope — all 50 states + DC + Puerto
 * Rico/USVI. It intentionally does NOT reject legitimate Alaska (including
 * the Aleutian islands, which cross the antimeridian into positive
 * longitude) or Hawaii or Puerto Rico lookups.
 *
 * Territory note (WARNING 2): Guam (~13.4N, 144.8E), American Samoa
 * (~-14.3S, -170.7W) and the Commonwealth of the Northern Mariana Islands
 * are INTENTIONALLY EXCLUDED from US_BBOX. This is a deliberate scope
 * decision (D-02 grants bbox-constant discretion to the planner), not an
 * oversight: no politician/geofence data is seeded for these territories
 * yet, so a "valid" classification for a point there would still resolve
 * to nothing downstream. Revisit when/if those territories are onboarded.
 *
 * D-03: the swap guard. A caller may submit (lat, lng) with the two axes
 * transposed (e.g. a JS object `{ lat: lng, lng: lat }` bug). If the
 * as-submitted point is outside the US box but swapping the two axes
 * lands inside the US box, we must NOT silently query the swapped point
 * as if it were valid — we return a distinct SWAPPED_COORDINATES code so
 * the caller can fix their request.
 */

/** Generous US bounding box: all 50 states + DC + PR/USVI, including the
 *  Aleutian sliver that crosses the antimeridian into positive longitude. */
export const US_BBOX = {
  lat: { min: 17.5, max: 72.0 },
  lng: {
    // Continental US + Alaska (most of it) + Hawaii + PR/USVI.
    primary: { min: -180.0, max: -64.0 },
    // The far-western Aleutian islands cross the antimeridian and are
    // reported as small POSITIVE longitudes (e.g. Attu Island ~173.1).
    aleutianSliver: { min: 172.0, max: 180.0 },
  },
};

export type CoordinateRejectionCode =
  | 'OUTSIDE_US_BOUNDS'
  | 'SWAPPED_COORDINATES'
  | 'INVALID_COORDINATES';

export type CoordinateClassification =
  | { ok: true }
  | { ok: false; code: CoordinateRejectionCode };

/** Internal: is (lat, lng) inside the generous US envelope? */
function inUsBox(lat: number, lng: number): boolean {
  if (lat < US_BBOX.lat.min || lat > US_BBOX.lat.max) return false;
  const inPrimaryLng = lng >= US_BBOX.lng.primary.min && lng <= US_BBOX.lng.primary.max;
  const inAleutianSliver = lng >= US_BBOX.lng.aleutianSliver.min && lng <= US_BBOX.lng.aleutianSliver.max;
  return inPrimaryLng || inAleutianSliver;
}

/**
 * classifyCoordinate — decide whether a submitted (lat, lng) is a valid US
 * point, an out-of-box point, a lat/lng-swapped point, or malformed input.
 *
 * Evaluation ORDER is load-bearing (this is the blocker fix — the malformed
 * guard must NOT pre-empt the swap branch):
 *   1. INVALID_COORDINATES ONLY for genuinely un-interpretable input — a
 *      non-finite value or a magnitude so absurd (>180 on EITHER axis) that
 *      no swap could ever make it valid. Deliberately does NOT apply a
 *      strict per-axis lat in [-90, 90] check here: a swapped US coordinate
 *      legitimately has a "latitude" slot beyond +/-90 (e.g. -93.0, which is
 *      really Minneapolis's longitude in the wrong slot) and MUST fall
 *      through to the swap guard below, not get rejected here.
 *   2. If (lat, lng) is in the US box -> ok.
 *   3. Swap guard (D-03): else if (lng, lat) is in the US box ->
 *      SWAPPED_COORDINATES. Never silently query the swapped point.
 *   4. Else -> OUTSIDE_US_BOUNDS.
 */
export function classifyCoordinate(lat: number, lng: number): CoordinateClassification {
  if (!Number.isFinite(lat) || !Number.isFinite(lng) || Math.abs(lat) > 180 || Math.abs(lng) > 180) {
    return { ok: false, code: 'INVALID_COORDINATES' };
  }

  if (inUsBox(lat, lng)) {
    return { ok: true };
  }

  if (inUsBox(lng, lat)) {
    return { ok: false, code: 'SWAPPED_COORDINATES' };
  }

  return { ok: false, code: 'OUTSIDE_US_BOUNDS' };
}
