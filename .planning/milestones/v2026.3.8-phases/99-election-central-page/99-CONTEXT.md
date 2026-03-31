# Phase 99: Election Central Page - Context

**Gathered:** 2026-03-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Build a dedicated Election Central view accessible via tab toggle on the existing Results page. Users see upcoming races for their address, grouped by government body and position, with candidate cards, incumbent badges, and election metadata. The same address search powers both the Representatives and Elections tabs.

</domain>

<decisions>
## Implementation Decisions

### Navigation & Entry Point
- **D-01:** Tab toggle on the Results page — "Representatives" / "Elections" tabs at the top. Address search persists across tab switches, no re-entry needed.
- **D-02:** Tab state reflected via URL search param (`?view=elections&address=...`). Shareable, back button works, current `/results` URL unchanged by default.
- **D-03:** Default tab is Representatives — existing behavior preserved. Elections tab is discoverable but not forced.
- **D-04:** Dot indicator on the Elections tab when upcoming elections exist (hidden when none). Subtle, no count — just signals there's election data.

### Race Card Layout
- **D-05:** Candidate grid cards — each race is a section header with candidate cards displayed in a grid, matching the same card style as the Representatives tab (reuse PoliticianCard pattern). Clicking a candidate navigates to their profile.
- **D-06:** Incumbent badge is a small "Incumbent" text label in ev-muted-blue below the candidate's name. Challengers get no badge.
- **D-07:** Election date and countdown displayed as a page-level header per election (not per race). E.g., "2026 Indiana Primary · May 6, 2026 · 32 days away". Multiple elections get separate headers.

### Grouping & Hierarchy
- **D-08:** Primary grouping: by election (chronological, soonest first). Each election gets its own header section with date/countdown.
- **D-09:** Secondary grouping: by tier within each election — Local > State > Federal (same tier order as Representatives tab). Use the same building images and CategorySection component from ev-ui.
- **D-10:** Tertiary grouping: by position within each tier. Follow the exact same ordering as the Representatives page (reuse `LOCAL_ORDER`, `STATE_ORDER`, `FEDERAL_ORDER` from `classify.js` and `GROUP_SORT_OPTIONS` from `sorters.js`). No custom importance sorting.
- **D-11:** Candidate order within each race is **seeded random per user** — stable for a user's session but randomized so no candidate appears favored by position. Consistent with the antipartisan mission and similar to the seeded stance randomization in the compass.

### Empty & Partial States
- **D-12:** Empty state when no elections exist: friendly centered message — "No upcoming elections found for this address. We're expanding coverage — check back as election season approaches." Not alarming, honest about coverage.
- **D-13:** No-photo fallback: initials avatar (candidate's initials in ev-muted-blue circle) — matches existing PoliticianCard fallback pattern.
- **D-14:** Elections tab dot indicator hidden when no elections exist — tab is still accessible but doesn't draw attention to emptiness.

### Claude's Discretion
- Loading skeleton design for the Elections tab
- Election header visual treatment (typography, spacing, card styling)
- Mobile responsive breakpoints for candidate card grid
- How to derive the seed for candidate randomization (user ID, session token, or localStorage key)
- Whether to prefetch election data when Representatives tab loads or lazy-load on tab switch

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Election Data Layer
- `ev-accounts/backend/src/lib/electionService.ts` — Election query API: `getElectionsByCoordinate(lat, lng)` returns elections → races → candidates with incumbent flag, geofence matching
- `ev-accounts/backend/src/routes/essentials.ts` — `GET /api/essentials/elections?lat=X&lng=Y` route definition
- `ev-accounts/backend/migrations/042_election_schema.sql` — Elections/races/race_candidates table definitions

### Existing Frontend Patterns
- `essentials/src/pages/Results.jsx` — Current Results page with address search, politician grid, tier grouping, building images. This is the page being extended with tab toggle.
- `essentials/src/pages/CandidateProfile.jsx` — Existing candidate profile page at `/candidate/:id`
- `essentials/src/lib/classify.js` — `classifyCategory()`, `FEDERAL_ORDER`, `STATE_ORDER`, `LOCAL_ORDER`, `orderedEntries()` — tier classification and ordering logic to reuse
- `essentials/src/utils/sorters.js` — `GROUP_SORT_OPTIONS`, `chainComparators` — sorting logic per category
- `essentials/src/lib/buildingImages.js` — `getBuildingImages()` for tier building photos
- `essentials/src/App.jsx` — Router definition, existing routes
- `essentials/src/hooks/useGooglePlacesAutocomplete.js` — Address search hook used by Results

### Shared Components
- `ev-ui` package — `CategorySection`, `PoliticianCard`, `useMediaQuery` components to reuse

### Prior Phase Context
- `.planning/phases/98-election-data-import/98-CONTEXT.md` — Election data import decisions, API design, incumbent matching strategy

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **PoliticianCard** (ev-ui): Candidate cards should match this style — same card treatment as Representatives tab
- **CategorySection** (ev-ui): Tier section wrapper with building images — reuse for Federal/State/Local grouping
- **classify.js**: Full tier classification and ordering logic — reuse `LOCAL_ORDER`, `STATE_ORDER`, `FEDERAL_ORDER` for race ordering within tiers
- **useGooglePlacesAutocomplete**: Address search hook already used by Results — shared across tabs
- **getBuildingImages / parseStateFromAddress**: Building image logic already wired up in Results
- **CandidateProfile page**: Already exists at `/candidate/:id` — candidate cards link here

### Established Patterns
- **Address flow**: Google Maps autocomplete → lat/lng → API call → display results. Elections tab follows same pattern with `/api/essentials/elections?lat=X&lng=Y`
- **Tier grouping**: Results page groups politicians by Federal/State/Local using `classifyCategory()` — Election Central mirrors this for races
- **URL state**: Results page already uses `useSearchParams` for address — extend with `view` param
- **Antipartisan**: No party information displayed anywhere. Candidate randomization reinforces this.

### Integration Points
- **Results.jsx**: Add tab toggle UI, conditionally render Representatives content or Elections content
- **App.jsx**: No new routes needed — Elections lives within `/results` via tab param
- **api.jsx**: Add `fetchElections(lat, lng)` function to call the existing election API endpoint

</code_context>

<specifics>
## Specific Ideas

- Candidate cards should be "basically the same as the ones on the results page" (user's words) — reuse PoliticianCard or create a minimal variant
- Tier order is Local first (same as Representatives page), not Federal first
- Candidate ordering within races must be randomized per user (seeded) to maintain antipartisan fairness — no candidate should appear to be prioritized by position

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 99-election-central-page*
*Context gathered: 2026-03-29*
