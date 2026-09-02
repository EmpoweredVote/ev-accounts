/**
 * jurisdictionPayload — reading `connect.resolve_user_jurisdiction`'s answer honestly.
 *
 * 🔴 THE PROBLEM THIS EXISTS TO SOLVE. That RPC builds its payload from aggregates with no
 * GROUP BY, so it returns exactly ONE row even when zero boundaries cover the point: every
 * key NULL, and NO error raised. `adminRpc` can also hand back `data: null`. Read either
 * through a bare `?? {}` and it says "every district is now NULL" — indistinguishable from
 * a genuine answer that the point is in no district.
 *
 * Proven against production 2026-08-27 with a positive control at a point in the Atlantic:
 * zero rows matched, one row returned, every key null, no error.
 *
 * FOUR call sites read this payload and they do NOT all want the same thing, which is
 * exactly why the question belongs in one place with one answer:
 *
 *   districtStalenessService  the point did not move, so an unresolved answer means "could
 *                             not resolve" and the stored value is still the best known.
 *                             It must NOT write. (This is the defect that shipped.)
 *   routes/connect set-location  the address just CHANGED, so the stored districts belong
 *                             to the old point and are definitively wrong. It MUST write,
 *                             nulls included — but it should say so.
 *   routes/essentials Path 1.5 (x2)  a back-fill for profiles whose geo_ids are already
 *                             empty. An unresolved answer has nothing to contribute, so
 *                             the write is pointless — and its guard checks fewer columns
 *                             than the UPDATE writes.
 *
 * So this module answers "how much did it resolve" and "what would this erase". Each caller
 * decides what to do about it. Do not add a policy here.
 */

/**
 * The five DISTRICT columns, paired with the RPC key that fills each one.
 *
 * 🔴 This list is not just a mapping table — `resolvedDistrictCount` counts it, and four
 * call sites branch on that count. Adding a key here changes what "the RPC resolved
 * nothing" means. See PLACE_FIELDS below for why city/state/nation are NOT in this list.
 */
export const GEO_FIELDS = [
  { column: 'congressional_geo_id', rpcKey: 'congressional' },
  { column: 'state_senate_geo_id', rpcKey: 'state_senate' },
  { column: 'state_house_geo_id', rpcKey: 'state_house' },
  { column: 'county_geo_id', rpcKey: 'county' },
  { column: 'school_district_geo_id', rpcKey: 'school_district' },
] as const;

/**
 * The three PLACE columns — the geoids a Civic Spaces slice is keyed on.
 *
 * 🔴 DELIBERATELY NOT PART OF GEO_FIELDS, and this is load bearing.
 *
 * `resolvedDistrictCount` counts GEO_FIELDS to answer "did the RPC resolve anything",
 * but the question underneath it is narrower: "is the essentials.districts join healthy".
 * That join is what silently broke and wiped profiles, and it is what the count detects.
 *
 * These three bypass essentials.districts entirely — they are read straight off
 * essentials.geofence_boundaries by mtfcc, because that table reuses geo_ids across
 * layers. So they CANNOT witness the join's health. Fold them in and a wholly broken
 * join still resolves a state and a nation: the count reads 2 instead of 0, every guard
 * reads that as success, and districtStalenessService goes back to writing NULLs over
 * districts that were never wrong.
 *
 * city_council_geo_id and municipality_geo_id are outside GEO_FIELDS for the same reason
 * and set the precedent: a column written from this payload is not thereby a district.
 *
 * `city` is null for unincorporated addresses. That is an answer, not a failure.
 */
export const PLACE_FIELDS = [
  { column: 'city_geo_id', rpcKey: 'city' },
  { column: 'state_geo_id', rpcKey: 'state' },
  { column: 'nation_geo_id', rpcKey: 'nation' },
] as const;

/** A jurisdiction payload as it arrives: possibly null, possibly all-NULL, never trusted. */
export type JurisdictionPayload = Record<string, string | null> | null | undefined;

/** The stored geo_id columns, as read from connect.connected_profiles. */
export type StoredDistricts = Partial<Record<(typeof GEO_FIELDS)[number]['column'], string | null>>;

/** The stored place geoid columns, as read from connect.connected_profiles. */
export type StoredPlaces = Partial<Record<(typeof PLACE_FIELDS)[number]['column'], string | null>>;

/**
 * How many of the five districts this payload actually names.
 *
 * 0 means the RPC resolved NOTHING — either the point is genuinely outside every boundary,
 * or the geo_id / mtfcc / district_type join inside the RPC is broken. Those two are
 * indistinguishable from here, which is the whole reason 0 must never be read as "changed".
 *
 * Only the geo_id keys count. A payload carrying district NAMES but no geo_ids has resolved
 * nothing; the names are labels for an id that is not there.
 */
export function resolvedDistrictCount(payload: JurisdictionPayload): number {
  if (!payload) return 0;
  return GEO_FIELDS.filter((f) => {
    const v = payload[f.rpcKey];
    return v !== null && v !== undefined && v !== '';
  }).length;
}

/**
 * Which stored district columns this payload would set to NULL.
 *
 * A column that was already empty is not "dropped" — writing NULL over NULL erases nothing.
 * Callers use this either to warn (a partial drop is real signal, but it is also the shape
 * a half-broken join takes) or to decide the write is not theirs to make.
 */
export function droppedDistricts(
  stored: StoredDistricts,
  payload: JurisdictionPayload
): string[] {
  return GEO_FIELDS.filter((f) => {
    const was = stored[f.column] ?? null;
    const now = payload?.[f.rpcKey] ?? null;
    return was !== null && now === null;
  }).map((f) => f.column);
}
