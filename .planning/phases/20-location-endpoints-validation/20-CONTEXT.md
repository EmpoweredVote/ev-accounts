# Phase 20: Location Endpoints & Validation - Context

**Gathered:** 2026-03-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Two new API endpoints that accept an address string, geocode it, encrypt and store the coordinates via the Phase 19 RPCs, and return jurisdiction data. Raw coordinates must never appear in any API response, server logs, or returned RPC data.

- `POST /api/connect/set-location` — accepts an address, geocodes it, stores encrypted coordinates, sets location_consent = true, returns jurisdiction JSON
- `GET /api/account/me/jurisdiction` — returns jurisdiction JSON for users who have set location consent; 403 otherwise

Also includes: LA County TIGER/Line boundary data load (runbook step) and an architecture test asserting no coordinate leakage.

</domain>

<decisions>
## Implementation Decisions

### Geocoding Provider
- **Google Maps Geocoding API** — chosen for accuracy and address parsing quality
- Call is server-side only; Google sees address strings from the server's IP, not the user's IP or identity
- **Discard address string immediately** after geocoding — never stored in Postgres or Redis
- **Reject low-confidence geocodes** — only accept ROOFTOP or RANGE_INTERPOLATED location_type; reject GEOMETRIC_CENTER and APPROXIMATE
- **Address not found** → 422 with user-facing message: "We couldn't find that address. Please double-check and try again."

### Request Shape
- Single address string: `{ "address": "123 Main St, Bloomington, IN 47401" }`
- No structured fields — Google handles address parsing
- PO Box validation (from success criteria): reject `PO Box`, `P.O. Box`, `POB` (case-insensitive) before any geocoding call

### Response Shape
- `POST /set-location` success returns jurisdiction JSON immediately — no second request required:
  ```json
  {
    "location_consent": true,
    "jurisdiction": {
      "congressional_district": "IN-09",
      "state_senate_district": "SD-40",
      "state_house_district": "HD-61",
      "county": "Monroe County",
      "school_district": "MCCSC"
    }
  }
  ```
- Flat key-value shape (not nested, not array)
- `GET /api/account/me/jurisdiction` returns the same jurisdiction JSON shape when consent is true; 403 when false or null (no distinction between "never set" and "revoked")

### Out-of-Coverage Handling
- Validate address is in coverage area **after geocoding** (coordinate-based check, not string parsing)
- Current coverage: Indiana + LA County, California
- Out-of-coverage → 422: "Your address is outside our current coverage area. We're expanding soon."
- Error message is generic — does not name specific states
- **LA County TIGER/Line data not yet loaded** — Phase 20 must include a runbook step to load LA County boundaries (ogr2ogr, similar pattern to Indiana in Phase 19 runbook)

### Consent & Revocation
- **No revocation in Alpha** — location_consent is one-way for now; deferred to a later phase
- **Upsert behavior** — calling set-location again with a new address overwrites encrypted coordinates and updates location_set_at; no error on repeat calls
- **Location gated to Connected + Empowered tier** — Inform-tier users (no connected_profiles row) receive 403
- `GET /account/me` returns `location_consent: boolean` only — full jurisdiction data requires a separate call to `GET /jurisdiction`

### Claude's Discretion
- Google Maps API key configuration (env var name, error handling if key missing)
- Exact architecture test implementation (static analysis of route files vs. runtime assertion)
- HTTP error codes for edge cases not explicitly covered above

</decisions>

<specifics>
## Specific Ideas

- PO Box rejection must fire before the geocoding call — no wasted API credits
- The coordinate leakage architecture test should pass with 0 violations — not a soft warning
- LA County load follows the same ogr2ogr pattern as Indiana (FIPS filter, SRID 4269→4326 reprojection) — reference Phase 19 runbook (RUNBOOK-TIGER-LOAD.md) for the command pattern

</specifics>

<deferred>
## Deferred Ideas

- Location consent revocation / DELETE endpoint — deferred to a later phase (post-Alpha)
- Support for states beyond Indiana + LA County — expand by loading additional TIGER/Line boundary data when scaling; no code change required, just runbook

</deferred>

---

*Phase: 20-location-endpoints-validation*
*Context gathered: 2026-03-13*
