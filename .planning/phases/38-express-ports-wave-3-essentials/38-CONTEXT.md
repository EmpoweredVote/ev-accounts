# Phase 38: Express Ports Wave 3 — Essentials - Context

**Gathered:** 2026-03-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Port all ~25 essentials routes from the Go server (api.empowered.vote) to ev-accounts Express API — including the address-search flow (Census Geocoder → PostGIS geofence → politician list), full politician profiles, and all legislative depth routes. Replace the existing Google Maps geocoder throughout. The Go server should have zero remaining essentials responsibility after this phase.

This is NOT a greenfield build — the essentials schema (35 tables) was migrated in Phase 34, two basic routes already exist (`GET /api/essentials/politicians` and `GET /api/essentials/candidates/:zip`), and the geocodingService.ts already handles address input for account setup. Phase 38 completes the port.

</domain>

<decisions>
## Implementation Decisions

### Census Geocoder — replacing Google Maps

- **Replace Google Maps everywhere**: `geocodingService.ts` is rewritten to use the US Census Geocoder (free). `connect.ts` address setup flow and all new Phase 38 address-search routes use the same new service.
- **Confidence rule**: Accept Census `matchStatus: 'Match'` (both exact and non-exact). Reject `matchStatus: 'No_Match'` with existing `ADDRESS_NOT_FOUND` error code. Non-exact matches are acceptable — Census correcting "St" to "Street" is fine for district lookup.
- **Timeout**: 5 seconds on the Census Geocoder HTTP call. Exceed → 503 with clear message.
- **Geocoder failure response**: Return HTTP 503 with `{ code: 'GEOCODER_UNAVAILABLE', message: 'Address lookup temporarily unavailable.' }`. Do not silently return empty results.

### Caching

- **Cache successful geocoder results** in Upstash Redis with a 24-hour TTL, keyed on the normalized address string. Reduces Census API dependency for repeat lookups.
- Existing Redis cache infrastructure (`lib/cache.ts`) is used — no new cache layer needed.

### PostGIS no-match behavior

- If geocoding succeeds but PostGIS finds no matching jurisdiction boundary: return HTTP 200 with `{ politicians: [], jurisdiction: null }`. This is not an error — it means we don't have coverage for that address yet. Client should show "no representatives found."

### Tier-differentiated responses

- **Same endpoint, conditional fields**: All essentials routes use `optionalAuth` middleware. If a valid Connected JWT is present, the response includes tier-specific additions. Unauthenticated requests receive baseline data.
- **`data_level` field**: Every response includes `"data_level": "inform"` or `"data_level": "connected"` so clients know which tier of data was returned and can prompt "connect your account to see more" when appropriate.
- **Auth model**: `optionalAuth` middleware throughout — public data works without a token, Connected JWT enriches responses. No session cookie support (ev-accounts is Bearer-only).

### Go parity

- **Strict parity**: Every essentials endpoint matches the Go server's response shape exactly — same field names, same nesting, same types. The Essentials frontend at Phase 40 cutover requires zero client-side changes to how it consumes response data.
- **Additive fields allowed**: The 9 `empowered_profiles` politician schema columns added in v1.3 (bio, photo_url, social handles, etc.) are appended to relevant politician responses as additional fields. These don't exist in the Go contract and are purely additive.
- **Research method**: The researcher queries the live Go server at api.empowered.vote for each essentials endpoint using a known Indiana address and politician ID, captures actual JSON responses, and uses those as the parity target.

### Route scope

- **Complete port — all ~25 routes in Phase 38**: Nothing left on the Go server after this phase. This includes:
  - `GET /essentials/address-search` — Census Geocoder → PostGIS → politicians (critical path)
  - `GET /essentials/politicians` — existing route, extend with `district_id`/`district_type` fields
  - `GET /essentials/politicians/:id` — full politician profile (critical path)
  - `GET /essentials/politicians/:id/legislative`
  - `GET /essentials/politicians/:id/committees`
  - `GET /essentials/politicians/:id/bills`
  - `GET /essentials/politicians/:id/votes`
  - `GET /essentials/governments/:id`
  - `GET /essentials/chambers/:id`
  - `GET /essentials/districts/:id`
  - Any additional routes discovered when researcher inspects the live Go server
- **Full join depth**: Each endpoint matches the full join depth of the Go response — no cutting corners on nested objects (images, contacts, endorsements, office history, etc.).
- **Existing routes extended**: `GET /api/essentials/politicians` already exists but needs `district_id` and `district_type` fields added (currently missing; ESSENTIALS-INTEGRATION.md Section 6 requires them for jurisdiction matching).

### Claude's Discretion

- Plan split / number of sub-plans
- SQL query structure for PostGIS geofence lookups
- Redis cache key format for geocoder results
- Error handling for individual missing records within nested joins
- Whether to extend existing `essentialsService.ts` or create new service files per domain (politicians, legislative, governments)

</decisions>

<specifics>
## Specific Ideas

- The user noted that Chris Andrews' team started with Google Maps but Census Geocoder is preferred for cost reasons. This is the correct long-term direction — Census Geocoder also returns FIPS codes natively which can simplify the PostGIS lookup step.
- Compass alignment on politician pages ("here's how this politician aligns with your priorities") is the right vision — but deliberately deferred to Phase 39 which is specifically about Compass Additions. Phase 38 ports the base essentials data only.
- ESSENTIALS-INTEGRATION.md was written in Phase 33 as a partial guide covering only the 5 routes already on ev-accounts. It has a documented gap (noted in PLATFORM-CONSOLIDATION.md Section 3.4): ~10 core endpoints need to be added. Phase 43 (Integration Documentation) is where this gets updated — not Phase 38.

</specifics>

<deferred>
## Deferred Ideas

- **Compass alignment on politician profiles** — When a Connected user views a politician's profile, show how that politician's compass calibration aligns with the user's own priorities. Requires joining compass data with essentials data. → Phase 39 (Compass Additions)
- **`data_level` tier signaling on existing non-essentials routes** — The `data_level` field pattern could be applied across other endpoints (account/me, compass, etc.) for consistency. → Post-Phase 38 consideration, not blocking.

</deferred>

---

*Phase: 38-express-ports-wave-3-essentials*
*Context gathered: 2026-03-20*
