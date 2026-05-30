# Phase 70: Geofencing Backend Integration - Context

**Gathered:** 2026-05-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire `cache_user_districts` into both the Connected location-set flow AND the Inform location-hint flow so all authenticated users get TIGER-backed district caching. Add `GET /api/account/districts` endpoint. Update `GET /essentials/representatives/me` to join politicians via `tiger_geoid` instead of live geo lookup.

Covers GEO-10, GEO-11, GEO-12.

</domain>

<decisions>
## Implementation Decisions

### Caching trigger behavior
- `cache_user_districts` runs **synchronously** within the location-save request — districts are ready when the response returns, no second call needed
- **Fail-open** on caching error: location saves successfully regardless; district caching failure is logged but does not block or rollback the location write
- Location-set endpoint **does NOT** return resolved districts in its response body — existing jurisdiction response shape is unchanged. Clients fetch districts separately via `GET /api/account/districts`. Security decision: address data flows in, gets encrypted and stored; it is never re-surfaced in response bodies.
- **Any location write** triggers re-cache — both initial set and subsequent updates (Connected location-set flow + Inform location-hint flow)

### Districts endpoint shape
- `GET /api/account/districts` — grouped by layer: `{ ca_assembly: {...}, ca_senate: {...}, us_house: {...} }`
- Each district entry contains district identity only: district number, name, `tiger_geoid` — no politician data
- Returns **204 No Content** when the user has no cached districts (no location set)
- Auth: **`requireAuth`** (any authenticated user, both Inform and Connected tiers) — Essentials is foundational to the Inform pillar, not a Connected-only feature

### Inform tier inclusion (Phase 70 scope)
- Both tiers are wired into district caching in this phase
- `PATCH /api/account/location-hint` (Inform flow) also triggers `cache_user_districts` using the lat/lng from the hint payload
- `GET /api/account/districts` is available to Inform users; returns 204 until they've saved a location through Essentials

### Representing-me transition (GEO-12)
- **New fast path (Path 0):** Check `user_districts` cache first; join politicians via `tiger_geoid` + `district_type` (both fields required — tiger_geoid is non-unique across SLDL/SLDU, e.g., assembly D20 and senate D20 both have `tiger_geoid='06020'`)
- **Opportunistic backfill:** Users with stored lat/lng but no cached districts (pre-Phase-70 users) get `cache_user_districts` triggered inline on their next call — they land on the fast path from that point forward. No separate migration script needed.
- **Path 2 upgrade:** When geocoding from home_address succeeds, the resulting lat/lng feeds `cache_user_districts` AND writes the coordinates back to `connected_profiles` permanently — future calls skip geocoding
- **Out-of-CA / no match:** If `cache_user_districts` returns zero matching districts (user outside CA or in a data gap), endpoint returns **204 No Content**
- Layer → district_type mapping for joins: `ca_assembly` → `STATE_LOWER`, `ca_senate` → `STATE_UPPER`, `us_house` → `NATIONAL_LOWER`

### Cache staleness + refresh
- **No TTL** — district boundaries are stable within a cycle; time-based re-caching is unnecessary overhead
- Re-caching triggered only by: (a) user location writes, (b) admin bulk re-cache script run after any TIGER import
- **Admin bulk re-cache script** (not an HTTP endpoint) — run after redistricting or new TIGER data imports; targets users where `resolved_at < [import date]` to avoid unnecessary re-runs
- No user-facing manual refresh endpoint — users have no way to know districts changed, and the admin script handles redistricting events
- `resolved_at` timestamp on `user_districts` (already present from Phase 69 migration) is used by the bulk re-cache script to target only outdated records

### Claude's Discretion
- How lat/lng is extracted from the Inform location-hint JSON payload (format of `last_essentials_location`)
- Whether `cache_user_districts` is called as a side effect inside the route handler or in a shared service wrapper
- Error logging format and severity level for failed district caching
- Structure of the admin bulk re-cache script (could be a standalone Node script or a new npm command)

</decisions>

<specifics>
## Specific Ideas

- The fail-open pattern on caching is critical — location saves are user-facing; a PostGIS hiccup should never surface as a location-save error
- Mid-decade redistricting is real (gerrymandering), so the admin re-cache mechanism needs to be production-ready, not just a nice-to-have
- The `resolved_at` field enables surgical re-caching: "re-cache anyone whose districts were resolved before [2026-MM-DD redistricting date]"

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed within phase scope

</deferred>

---

*Phase: 70-geofencing-backend-integration*
*Context gathered: 2026-05-09*
