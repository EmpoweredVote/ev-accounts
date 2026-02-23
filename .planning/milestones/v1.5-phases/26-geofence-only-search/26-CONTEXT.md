# Phase 26: Geofence-Only Search - Context

**Gathered:** 2026-02-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Address search returns politicians using geofence matching only. When local geofence data is unavailable, federal and state officials are returned from cache. No BallotReady API call fires during any search path. The ZIP-based search endpoint is replaced by address-only search. Phase 28 adds Google Maps autocomplete on top of this.

</domain>

<decisions>
## Implementation Decisions

### Fallback behavior
- When geofence returns zero local results, the response includes federal + state officials AND an explicit empty local section (signals to frontend that local was attempted but unavailable)
- Federal/state officials use a new address-aware lookup path that resolves address -> state -> officials in one step (not reusing the existing per-ZIP cache tables)
- Partial local results are returned as-is — if geofence matches county but not city council, show whatever matched. Some data is better than none.

### Response headers & signals
- `X-Data-Status` header communicates coverage status to the frontend
- Response body contains politician data only — no metadata about coverage in the body. Header is sufficient.
- Response shape stays identical to today's format for the happy path — frontend doesn't need changes for full-coverage results
- Address search endpoint replaces the ZIP search endpoint entirely

### Search flow UX
- Results grouped by Federal / State / Local tiers. When no local coverage, the Local section is visible but shows an empty-state message instead of cards.
- Same loading UX regardless of how fast geofence responds — keep the existing loading skeleton/spinner pattern
- Partial local results shown as-is with no "incomplete" indicator — users won't know what's missing
- Dashboard switches from ZIP input to address text input in this phase (not waiting for Phase 28 autocomplete)
- Confirmed/formatted search address displayed at the top of results (e.g., "Showing results for Bloomington, IN")

### Geofence coverage messaging
- Tone: informational and matter-of-fact — "Local representative data is not yet available for this area."
- Placement: message sits inside the empty Local tier section, replacing where politician cards would be
- No call-to-action — just the informational message, keep it clean

### Claude's Discretion
- Handling of unresolvable addresses (invalid, PO box, etc.) — Claude picks based on what makes sense for the API contract
- X-Data-Status header value design (binary vs three-tier) — Claude designs based on what the frontend needs
- Internal geocoding approach for address -> state resolution

</decisions>

<specifics>
## Specific Ideas

- The empty local section message should match the existing dashboard visual style — not a big warning banner, just a calm placeholder where cards would normally be
- "Showing results for [address]" at the top gives users confidence their search was understood correctly

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 26-geofence-only-search*
*Context gathered: 2026-02-22*
