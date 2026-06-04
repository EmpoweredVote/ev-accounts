# Phase 99: election-central-page - Context

**Gathered:** 2026-06-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Human-verify the elections page at `essentials.empowered.vote/elections`, fix every issue found, and declare the elections feature shipped. Plans 99-01 (backend) and 99-02 (frontend wiring) are already complete — this phase is verification and close-out only.

</domain>

<decisions>
## Implementation Decisions

### Verification Method
- **D-01:** Use Playwright to browser-drive the live site (`essentials.empowered.vote`). The `/elections` route redirects to `/results?prefilled=true&view=elections` — Playwright must follow that redirect.
- **D-02:** Four things to check: (1) page loads with no JS errors, (2) enter a Salt Lake City UT address and confirm elections list appears, (3) data spot-check — compare what the page renders against `essentials.elections` + `essentials.races` + `essentials.race_candidates` in the DB, (4) mobile/responsive check at 375px width.
- **D-03:** Test address: a Salt Lake City, UT address (e.g. `123 Main St, Salt Lake City, UT 84101`). Utah primary is June 23 2026 — nearest upcoming election with the richest data.

### Data Scope
- **D-04:** Verify upcoming elections only (`election_date >= current_date`). Past elections are historical and not worth validating.
- **D-05:** Data spot-check must confirm: (a) election dates displayed match DB, (b) candidate names match `essentials.politicians`, (c) race count for the election matches `essentials.races`, (d) no withdrawn candidates appear in results (current backend filters `candidate_status != 'withdrawn'`).
- **D-06:** Note: a withdrawn-candidate-with-badge feature was documented (ESSENTIALS-NOTE 2026-04-13) but status is unconfirmed. Playwright should verify whether withdrawn candidates are silently filtered or shown with a badge.

### Fix Ownership
- **D-07:** UI bugs → direct commit to `C:\Transparent Motivations\essentials`. Render auto-deploys from master — no PR needed.
- **D-08:** Data bugs (wrong dates, missing races, bad candidate records) → SQL migration in this repo (`backend/migrations/`), applied via existing migration runner.
- **D-09:** If the withdrawn-candidate-badge feature is incomplete, it counts as a UI fix in the essentials repo.

### Ship Declaration Bar
- **D-10:** ELEC-03 requires: smoke test passes (page loads, elections list renders for UT address, no console errors) + `MILESTONES.md` updated to note elections feature shipped. No manual approval checkpoint needed — agent can write the milestone entry directly.
- **D-11:** Wave 2 fixes everything found in Wave 1. Wave 3 smoke test re-runs, then closes ELEC-01/02/03 and writes the milestone entry.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` §Elections — ELEC-01, ELEC-02, ELEC-03 (the three requirements this phase closes)
- `.planning/ROADMAP.md` §Phase 99 — goal, waves, success criteria

### Backend — Election Service
- `backend/src/lib/electionService.ts` — `getElectionsByCoordinate()`, `getElectionsByGeoIds()`, candidate/race grouping, `candidate_status != 'withdrawn'` filter
- `backend/src/routes/essentials.ts` — `GET /api/essentials/elections` and `GET /api/essentials/elections-by-address` route definitions

### Frontend — Elections UI (essentials repo)
- `C:\Transparent Motivations\essentials\src\components\ElectionsView.jsx` — 777-line election display component (race cards, candidate cards, tier grouping, compass integration)
- `C:\Transparent Motivations\essentials\src\pages\Results.jsx` — host page; handles address input, calls `fetchElectionsByAddress()`, passes `electionsData` to `ElectionsView`
- `C:\Transparent Motivations\essentials\src\App.jsx` — `/elections` redirects to `/results?prefilled=true&view=elections`

### Known Issues + Prior Fixes
- `ESSENTIALS-NOTE-elections-state-federal-2026-04-13.md` — CA geofence bug (MTFCC swap, county-vs-district collision) fixed; 16 LA County races seeded; MTFCC-aware ST_Covers join in `electionService.ts`
- `ESSENTIALS-NOTE-withdrawn-candidates-elections-page-2026-04-13.md` — withdrawn candidate display design: show with "WITHDRAWN" badge (not silently hidden). Implementation status unconfirmed — Wave 1 must check.

### Election Data
- `backend/migrations/042_election_schema.sql` — base schema
- `backend/migrations/237_or_2026_elections.sql` — Oregon 2026 elections
- `backend/migrations/251_multnomah_elections.sql` — Multnomah County elections
- `backend/data/election-research/2026-06-23-utah-primary.csv` — Utah primary source data

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ElectionsView.jsx`: fully built 777-line component. Handles Federal/State/Local tier grouping, candidate cards, compass score integration, seeded shuffle for antipartisan ordering. Do not rebuild — fix in place.
- `cleanPositionName()` export in `ElectionsView.jsx` — strips leading zeros from district numbers, abbreviates "United States Representative" → "US Representative".
- `Results.jsx` elections tab: eager-fetches elections on address search, handles `fetchElectionsByGovernmentList` / `fetchElectionsByArea` / `fetchMyElections` / `fetchElectionsByAddress` branches.

### Established Patterns
- Antipartisan: `primary_party` never rendered in UI. Election type shown as "Primary Election" / "General Election" generically.
- `publicFetch` (not `apiFetch`) for elections data — public endpoint, no auth redirect loop.
- `classifyCategory(district_type)` duck-typing for tier grouping.
- Withdrawn candidates: current backend filters them at JOIN level (`candidate_status != 'withdrawn'`); ESSENTIALS-NOTE specifies they should appear with a badge instead.

### Integration Points
- Backend `GET /api/essentials/elections-by-address` → `Results.jsx` `fetchElectionsByAddress()` → `ElectionsView.jsx`
- DB: `essentials.elections` → `essentials.races` → `essentials.race_candidates` → `essentials.politicians` (photo, name)
- Geocoding: Census geocoder via `geocodeAddress()` in `backend/src/lib/geocoding.ts`

</code_context>

<specifics>
## Specific Ideas

- Test address for verification: `123 Main St, Salt Lake City, UT 84101` — Utah primary June 23 2026
- Mobile check: 375px viewport width
- Withdrawn candidate badge: the ESSENTIALS-NOTE says "show with WITHDRAWN overlay/banner on photo, not silently removed." Wave 1 should confirm whether this is already implemented or still needs to be.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 99-election-central-page*
*Context gathered: 2026-06-03*
