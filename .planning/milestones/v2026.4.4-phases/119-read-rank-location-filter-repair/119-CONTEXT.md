# Phase 119: Read & Rank Location Filter Repair - Context

**Gathered:** 2026-04-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Diagnose and repair the Monroe County location filter in Read & Rank so that entering
a Monroe County address scopes the displayed quote list to local candidates. Both filter
mechanisms (address geocoding and browse-by-location) must be functional and verified
against a Monroe County test address on production.

**In scope:**
- End-to-end diagnosis: DB quotes → API endpoints → frontend filter wiring
- Address mode: Google Places autocomplete → `searchPoliticians()` → Census Geocoder → politician IDs
- Browse mode: State → Area Type → Area dropdowns → `browse/by-area` PostGIS intersection
- IssueHub filter predicate (`locationFilter.politicianIds` intersection with quote `candidateId`)
- CORS/routing verification between readrank.empowered.vote and api.empowered.vote
- Zero-state UX when location filter yields no matching issues

**Out of scope:**
- Verdict badge rendering (Phase 118)
- Cross-app loop polish (Phase 122)
- Geofence correctness for specific districts (Phase 121 — D1→D4 fix)
- New filter features or UI redesign

</domain>

<decisions>
## Implementation Decisions

### Diagnosis Scope
- **D-01:** Root cause is **unknown** — research step must diagnose end-to-end across
  both filter paths before any code changes. Do not assume the break is in one layer.
- **D-02:** Both **address mode** (Census Geocoder path) and **browse mode** (PostGIS
  browse-by-area path) must be investigated. Either or both could be broken.
- **D-03:** Diagnosis should check: (a) do Monroe County politicians have quotes in the
  DB? (b) do the API endpoints return politician IDs for a Monroe County address/area?
  (c) does the frontend correctly wire those IDs into the filter predicate?

### Filter Behavior
- **D-04:** Keep the **2+ unique local reps** threshold per issue — Read & Rank needs
  at least 2 candidates for meaningful matchups. Do not lower to 1.
- **D-05:** Issues with fewer than 2 local reps with quotes remain **hidden entirely**
  when the location filter is active (current behavior preserved).
- **D-06:** When the location filter returns **zero matching issues**, show a message
  like "No issues with local quotes for this area" with a **clear filter button** to
  guide the user back to the unfiltered view. Do not auto-clear silently.

### Backend Wiring
- **D-07:** CORS/routing between readrank.empowered.vote and api.empowered.vote is
  **unverified** — research step must test both `/essentials/candidates/search` and
  `/essentials/browse/*` endpoints from the readrank origin and check CORS headers.
- **D-08:** Google Maps Places API key is **confirmed configured** on readrank.empowered.vote
  — address mode autocomplete should function; if it doesn't, the break is downstream
  of Places (in the geocoder or politician lookup).

### Verification
- **D-09:** Use the **Kirkwood Ave Bloomington test address** from Phase 121's MATRIX.md
  as the canonical test case for RR-03/RR-04 verification.
- **D-10:** Final verification must happen **on production** (readrank.empowered.vote)
  after Render deploy — local dev is fine for iteration but production is the source
  of truth, consistent with Phase 118's verification approach.
- **D-11:** Both address and browse paths must be verified against the Monroe County
  test address/area — fixing only one path is insufficient.

### Claude's Discretion
- Exact diagnostic commands, DB queries, and API inspection steps during investigation.
- Which layer to fix first if multiple breaks are found (suggest: fix data gaps first,
  then wiring, then frontend).
- Whether to add a defensive empty-state message in the existing code or create a new
  component for the zero-state UX (D-06).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements
- `.planning/ROADMAP.md` §"Phase 119" — phase goal and success criteria
- `.planning/REQUIREMENTS.md` RR-03, RR-04 — acceptance criteria

### Frontend — Read & Rank Location Filter
- `read-rank/src/components/AddressFilterInput.tsx` — dual-mode filter input (address + browse)
- `read-rank/src/components/IssueHub.tsx` §59–66 — filter predicate: requires 2+ unique
  local reps with quotes per issue via `locationFilter.politicianIds`
- `read-rank/src/store/useReadRankStore.ts` §82–106, §559–604 — `LocationFilter` type,
  `setLocationFilter`, `clearLocationFilter` state management
- `read-rank/src/data/api.ts` §58–78 — `searchPoliticians()` calls
  `POST /essentials/candidates/search`
- `read-rank/src/hooks/useGooglePlacesAutocomplete.ts` — Google Places autocomplete hook

### Backend — Search & Browse Endpoints
- `ev-accounts/backend/src/routes/essentialsCandidates.ts` §59–93 —
  `POST /essentials/candidates/search` (Census Geocoder path)
- `ev-accounts/backend/src/routes/essentialsBrowse.ts` — three browse endpoints:
  `GET /states`, `GET /states/:state/areas`, `POST /by-area`
- `ev-accounts/backend/src/lib/essentialsBrowseService.ts` — browse service layer
  (`getStatesWithData`, `getAreasForState`, `getPoliticiansByArea`)

### Phase 121 Test Address
- `.planning/MATRIX.md` or Phase 121 roadmap entry — Kirkwood Ave Bloomington test address
  (shared test case for geofence verification)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`AddressFilterInput`** — fully built dual-mode component with address (Google Places)
  and browse (State → Area cascading dropdowns) paths. Both modes call `setLocationFilter()`
  with `{ address, politicianIds }`.
- **`searchPoliticians()`** — API helper that POSTs to `/essentials/candidates/search` and
  returns `{ status, data: SearchPolitician[], formattedAddress }`.
- **Browse backend** — `essentialsBrowse.ts` has three working endpoints with PostGIS
  area intersection logic. States, areas, and by-area all implemented.
- **Zustand store** — `locationFilter` state with `set`/`clear` methods already wired.

### Established Patterns
- **`apiFetch()` from `lib/auth.ts`** — all API calls go through this wrapper which
  handles auth headers and 401 redirects. Both filter paths use it.
- **`VITE_API_URL` env var** — controls API base URL; production points to
  `api.empowered.vote`.
- **IssueHub filter predicate** — uses `Set` intersection of `locationFilter.politicianIds`
  with quote `candidateId` values. Requires `candidateId` to be non-null on quotes.

### Integration Points
- **Quote → Politician linkage** — quotes must have a `candidateId` field that matches
  politician `id` values returned by the search/browse endpoints. A mismatch here would
  silently blank the filter results.
- **Census Geocoder** — address mode depends on external Census Geocoder service being
  reachable from the backend. If it's down, address mode fails with a 503.
- **Google Places** — address mode depends on Places autocomplete firing the
  `onPlaceSelected` callback with a formatted address string.

</code_context>

<specifics>
## Specific Ideas

- The Kirkwood Ave Bloomington address (from Phase 121 MATRIX.md) is the canonical test case.
- Both filter modes must work — address search and browse-by-location.
- The `candidateId` field on quotes is the key linkage — if Monroe County politicians
  don't have quotes with matching `candidateId` values, the filter will return empty
  regardless of whether the API works correctly.
- Phase 118 (verdict badges) is a dependency in spirit — if verdict rendering is broken,
  it could mask whether the filter is working (badges won't show even if quotes are filtered
  correctly). But Phase 119 can proceed independently since the filter scopes *issues*, not
  *badges*.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 119-read-rank-location-filter-repair*
*Context gathered: 2026-04-15*
