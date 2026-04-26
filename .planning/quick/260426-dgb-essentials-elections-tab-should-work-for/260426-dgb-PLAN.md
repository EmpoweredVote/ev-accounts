---
quick_id: 260426-dgb
type: execute
autonomous: false
files_modified:
  - ev-accounts/backend/src/lib/essentialsBrowseService.ts
  - ev-accounts/backend/src/lib/electionService.ts
  - ev-accounts/backend/src/routes/essentialsBrowse.ts
  - essentials/src/lib/api.jsx
  - essentials/src/pages/Results.jsx
must_haves:
  truths:
    - "When a user picks a county/city/township in browse mode and switches to the Elections tab, races for that jurisdiction (and overlapping nested ones) appear instead of empty state."
    - "When a user uses a `?browse_geo_id=...&browse_mtfcc=...` shortcut (e.g. LA County), the Elections tab is populated."
    - "Address mode behavior is unchanged — `/essentials/elections-by-address` still drives that flow."
    - "No backend schema changes; the candidates-vs-politicians data-model gap is untouched (elections use the existing `races` + `race_candidates` tables, which already have an optional `politician_id` link)."
  artifacts:
    - path: "ev-accounts/backend/src/lib/essentialsBrowseService.ts"
      provides: "Exported helper `getOverlappingGeoIdsForArea(geoId, mtfcc) => { geoIds: string[]; stateAbbrev: string | null }` extracted from the existing intersection logic in `getPoliticiansByArea`."
    - path: "ev-accounts/backend/src/routes/essentialsBrowse.ts"
      provides: "POST /api/essentials/browse/elections-by-area endpoint."
    - path: "essentials/src/lib/api.jsx"
      provides: "`fetchElectionsByArea(geoId, mtfcc)` client helper."
    - path: "essentials/src/pages/Results.jsx"
      provides: "Elections eager-fetch effect branches on `searchMode` — uses `fetchElectionsByArea` in browse mode and resets correctly when the browsed area changes."
  key_links:
    - from: "essentials/src/pages/Results.jsx (elections eager-fetch useEffect)"
      to: "POST /api/essentials/browse/elections-by-area"
      via: "fetchElectionsByArea(geoId, mtfcc) when searchMode === 'browse'"
    - from: "ev-accounts/backend/src/routes/essentialsBrowse.ts (POST /elections-by-area)"
      to: "essentialsBrowseService.getOverlappingGeoIdsForArea + electionService.getElectionsByGeoIds"
      via: "shared PostGIS intersection + existing geo-id-based election query"
---

<objective>
Make the Elections tab work in browse-by-location mode (county/state/city/township).

Currently the Elections tab renders empty in browse mode because `Results.jsx` always calls `fetchElectionsByAddress(activeQuery)`, but `activeQuery` in browse mode isn't a geocodable address.

The backend already has the right primitives:
- `essentialsBrowseService.getPoliticiansByArea(geoId, mtfcc)` runs a PostGIS intersection that produces all overlapping district `geo_id`s for a selected area, and resolves the state abbrev.
- `electionService.getElectionsByGeoIds(geoIds, state)` returns upcoming elections + races + candidates for those geo_ids plus statewide races.

We just need to (a) expose a browse-mode elections endpoint that composes those two, and (b) wire the frontend Elections tab to call it when in browse mode.

Purpose: Browse-by-location users (LA County, statewide IN, etc.) get the same Elections tab experience as address-mode users — without geocoding.

Output: One new backend endpoint, one extracted helper, one new client helper, one branched useEffect in Results.jsx.
</objective>

<context>
@CLAUDE.md
@.planning/STATE.md

@essentials/src/pages/Results.jsx
@essentials/src/pages/Elections.jsx
@essentials/src/components/ElectionsView.jsx
@essentials/src/components/LocationBrowser.jsx
@essentials/src/lib/api.jsx
@ev-accounts/backend/src/routes/essentials.ts
@ev-accounts/backend/src/routes/essentialsBrowse.ts
@ev-accounts/backend/src/lib/essentialsBrowseService.ts
@ev-accounts/backend/src/lib/electionService.ts

<interfaces>
Existing — DO NOT change shapes:

```ts
// ev-accounts/backend/src/lib/electionService.ts
export interface ElectionResult { election_id; election_name; election_date; election_type; jurisdiction_level; races: ElectionRace[] }
export interface ElectionRace    { race_id; position_name; primary_party; seats; district_type; candidates: ElectionCandidate[] }
export interface ElectionCandidate { candidate_id; full_name; first_name; last_name; photo_url; is_incumbent; candidate_status; politician_id }

export async function getElectionsByGeoIds(
  geoIds: (string | null | undefined)[],
  state: string | null | undefined
): Promise<ElectionResult[]>;

// ev-accounts/backend/src/lib/essentialsBrowseService.ts
//   - existing internal logic in getPoliticiansByArea computes:
//       const allGeoIds = [geoId, ...intersectedGeoIds]
//       const stateFips = (geofence_boundaries.state for {geoId,mtfcc})
//       const stateAbbrev = FIPS_TO_ABBREV[stateFips]
//   - This is what we need to extract.
```

Existing browse routes already use `optionalAuth` and accept `{ geo_id, mtfcc }` in the body of POST /by-area. Mirror that contract.

Frontend `Results.jsx` already tracks `searchMode` ('address' | 'browse'), `activeQuery` (address mode), and the `?browse_geo_id` / `?browse_mtfcc` URL params (browse-shortcut mode). The current elections effect keys on `[activeQuery]`. The new effect must also fire for browse mode and re-fire when geo_id/mtfcc changes.

Address-mode elections fetch (`fetchElectionsByAddress`) returns `{ elections, error }`. Match that shape for `fetchElectionsByArea` so the consuming `setElectionsData(data.elections || [])` line still works.
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Backend — extract overlap helper and add browse-mode elections endpoint</name>
  <files>
    ev-accounts/backend/src/lib/essentialsBrowseService.ts,
    ev-accounts/backend/src/routes/essentialsBrowse.ts
  </files>
  <action>
    1. In `ev-accounts/backend/src/lib/essentialsBrowseService.ts`, extract the existing intersection + state-resolution logic from `getPoliticiansByArea` into a new exported helper:

       ```ts
       export async function getOverlappingGeoIdsForArea(
         geoId: string,
         mtfcc: string
       ): Promise<{ geoIds: string[]; stateAbbrev: string | null }>
       ```

       It should run the same `intersectionQuery` that's already there, build `allGeoIds = [geoId, ...intersected]`, then run the same `geofence_boundaries` lookup to map FIPS state → `stateAbbrev` via the existing `FIPS_TO_ABBREV` map.

       Refactor `getPoliticiansByArea` to call this helper instead of duplicating the queries. Keep its return shape and behavior identical (verified by the existing `/browse/by-area` route still working unchanged).

    2. In `ev-accounts/backend/src/routes/essentialsBrowse.ts`, add a new route:

       ```ts
       // POST /api/essentials/browse/elections-by-area
       // Body: { geo_id: string, mtfcc: string }
       // Returns: { elections: ElectionResult[] }
       router.post('/elections-by-area', optionalAuth, async (req, res) => { ... });
       ```

       Implementation:
       - Validate `geo_id` and `mtfcc` exactly like `/by-area` does (422 on missing/empty).
       - Call `getOverlappingGeoIdsForArea(geo_id, mtfcc)`.
       - Call `getElectionsByGeoIds(geoIds, stateAbbrev)` from `electionService`.
       - Return `res.status(200).json({ elections })` to match the response shape used by `/elections-by-address` (frontend `ElectionsView` consumes `data.elections`).
       - Set `X-Data-Status` header: `'no-geofence-data'` if `geoIds.length === 0`, else `'fresh'` (mirrors the sibling route).
       - Wrap in try/catch and return 500 with `{ code: 'INTERNAL_ERROR', message: 'Failed to fetch election data' }` on error.

       Import `getElectionsByGeoIds` from `'../lib/electionService.js'`.

    Data-model note (do not skip): the elections data flows entirely through `essentials.races` and `essentials.race_candidates`. We are NOT touching `essentials.politicians`, so this work is unaffected by the candidates-vs-politicians mixing issue documented in CLAUDE.md. Candidates in `race_candidates` already have an optional `politician_id` link, which is what `getElectionsByGeoIds` returns.
  </action>
  <verify>
    <automated>cd ev-accounts/backend && npm run typecheck</automated>
    Plus a manual smoke from the repo root:
    - Start backend (`cd ev-accounts/backend && npm run dev`).
    - `curl -X POST http://localhost:3000/api/essentials/browse/elections-by-area -H 'Content-Type: application/json' -d '{"geo_id":"<known LA County geo_id>","mtfcc":"G4020"}' | jq '.elections | length'` returns a number > 0 if elections exist for that area, or 0 with a 200 status otherwise.
    - `curl -X POST .../elections-by-area -H 'Content-Type: application/json' -d '{}'` returns 422 with `VALIDATION_ERROR`.
    - Sanity-check `/api/essentials/browse/by-area` still works for the same geo_id (regression check on the refactor).
  </verify>
  <done>
    - `getOverlappingGeoIdsForArea` exported and used by `getPoliticiansByArea` (no behavior change).
    - `POST /api/essentials/browse/elections-by-area` returns `{ elections: [...] }` shape with proper validation, error handling, and `X-Data-Status` header.
    - `npm run typecheck` passes.
  </done>
</task>

<task type="auto">
  <name>Task 2: Frontend — wire Elections tab to browse-mode endpoint in Results.jsx</name>
  <files>
    essentials/src/lib/api.jsx,
    essentials/src/pages/Results.jsx
  </files>
  <action>
    1. In `essentials/src/lib/api.jsx`, add a new helper modeled on `fetchElectionsByAddress`:

       ```js
       export async function fetchElectionsByArea(geoId, mtfcc) {
         try {
           const res = await publicFetch('/essentials/browse/elections-by-area', {
             method: 'POST',
             headers: { 'Content-Type': 'application/json' },
             body: JSON.stringify({ geo_id: geoId, mtfcc }),
           });
           if (!res || !res.ok) return { elections: [], error: 'fetch_failed' };
           return await res.json(); // { elections }
         } catch (err) {
           console.error('fetchElectionsByArea error:', err);
           return { elections: [], error: 'fetch_failed' };
         }
       }
       ```

       Use whichever fetch wrapper `fetchElectionsByAddress` uses (publicFetch vs apiFetch) — match it for consistency. The browse `/by-area` route is `optionalAuth`, so anonymous calls must work.

    2. In `essentials/src/pages/Results.jsx`:
       - Add `fetchElectionsByArea` to the existing import from `'../lib/api'`.
       - Track the active browse area in a derived value. The current code reads `searchParams.get('browse_geo_id')` and `searchParams.get('browse_mtfcc')` for the shortcut path, and the `LocationBrowser` interactive path sets `browseResults` via the parent. The simplest and most correct trigger for the elections fetch in browse mode is the URL params (which the LocationBrowser flow should also set when it kicks off a browse — verify by reading the existing `LocationBrowser` integration in Results.jsx around line ~466 onward; if the interactive path does NOT push these params, also accept a fallback where we pass geoId/mtfcc through component state captured when the browse runs).
       - Replace the single elections eager-fetch `useEffect` (around line 430) with a branched version:

         ```jsx
         useEffect(() => {
           if (electionsData !== null) return;
           let cancelled = false;

           if (searchMode === 'browse') {
             const geoId = searchParams.get('browse_geo_id') || currentBrowseGeoId;
             const mtfcc = searchParams.get('browse_mtfcc') || currentBrowseMtfcc;
             if (!geoId || !mtfcc) return;
             setElectionsLoading(true);
             fetchElectionsByArea(geoId, mtfcc).then((data) => {
               if (!cancelled) {
                 setElectionsData(data.elections || []);
                 setElectionsLoading(false);
               }
             });
           } else {
             if (!activeQuery) return;
             setElectionsLoading(true);
             fetchElectionsByAddress(decodeURIComponent(activeQuery)).then((data) => {
               if (!cancelled) {
                 setElectionsData(data.elections || []);
                 setElectionsLoading(false);
               }
             });
           }

           return () => { cancelled = true; };
         }, [activeQuery, searchMode, /* browse geo_id + mtfcc */]);
         ```

       - Update the existing reset effect (line ~448–451: `setElectionsData(null)` on `[activeQuery]`) to also reset when the browse area changes. Add a parallel reset effect keyed on browse geo_id + mtfcc, OR fold it into a single effect keyed on whichever identifier is currently active.
       - If the interactive `LocationBrowser` path doesn't already store `geo_id` + `mtfcc` somewhere accessible to Results.jsx, capture them in component state when the browse fires. Inspect the `LocationBrowser` callback wiring in Results.jsx before deciding — do not invent new prop contracts unless needed.

    3. The Elections tab label/badge logic (`electionsLabelSuffix`, `electionsDaysAway`) reads from `electionsData` and is mode-agnostic — it should "just work" once browse-mode `electionsData` is populated. Verify visually rather than refactor.

    Antipartisan / data-model reminder: candidates in the response include `is_incumbent`, `candidate_status`, and `politician_id` only — no party tags are surfaced beyond `race.primary_party` (which `ElectionsView` already handles for primaries). Do not add party-derived UI in browse mode.
  </action>
  <verify>
    <automated>cd essentials && npm run build</automated>
    Plus user-driven manual checks (gated by checkpoint task below):
    - With backend running locally and frontend dev server, navigate to Results page in browse mode (e.g., via the LA County shortcut, or LocationBrowser → pick IN → Monroe County → Browse).
    - Switch to the Elections tab. Confirm races render (Local/State/Federal sections, branch dividers, candidate cards) instead of the empty state.
    - Switch back to Representatives — should still work.
    - Change browse area (e.g. switch to a different county) → Elections tab refetches and shows the new area's races.
    - Open address mode (enter a real address) → Elections tab still works exactly as before.
  </verify>
  <done>
    - `fetchElectionsByArea` exists in `essentials/src/lib/api.jsx` and returns `{ elections, error? }`.
    - `Results.jsx` Elections eager-fetch branches on `searchMode` and uses `fetchElectionsByArea(geoId, mtfcc)` for browse mode, with proper reset when the browsed area changes.
    - Browse-mode Elections tab visibly renders races for LA County and Monroe County (the two existing shortcut targets) when those areas have race data; renders the existing empty state cleanly when they don't.
    - Address-mode Elections tab is unchanged.
    - `npm run build` in `essentials/` succeeds.
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>
    Browse-mode Elections tab now calls a new POST /api/essentials/browse/elections-by-area endpoint that returns the same election/race/candidate shape as the address-mode endpoint, fed by the same PostGIS area intersection that already powers /browse/by-area.
  </what-built>
  <how-to-verify>
    1. Pull, run `cd ev-accounts/backend && npm run dev` and `cd essentials && npm run dev`.
    2. From Landing, click "Browse by location" (or hit `/results?browse_geo_id=<LA_County_geo_id>&browse_mtfcc=G4020&browse_label=LA%20County&mode=browse`). Switch to the Elections tab. Expected: races render for LA County (county-level + city-level + school-board + statewide CA races as applicable). Verify the tab label badge ("Elections — N races" / days-away dot) shows up if there's an upcoming election.
    3. Use LocationBrowser interactively: pick IN → Monroe County → Browse → switch to Elections. Expected: races for that area.
    4. Switch to a different county in the browser. Expected: Elections tab refetches and shows the new area's races (no stale data from the previous area).
    5. Address mode regression: enter "100 W Kirkwood Ave, Bloomington, IN 47404", switch to Elections. Expected: identical behavior to before this change.
    6. Empty case: pick a state/area that has no upcoming elections in the DB. Expected: the existing "No upcoming elections found" empty state — not a spinner forever and not a crash.
  </how-to-verify>
  <resume-signal>Type "approved" or describe issues</resume-signal>
</task>

</tasks>

<verification>
- `npm run typecheck` in ev-accounts/backend passes.
- `npm run build` in essentials/ passes.
- Manual flows in checkpoint pass.
</verification>

<success_criteria>
Browse mode Elections tab populates with races for the selected jurisdiction (county / city / township / state via shortcut), matching the visual structure of address-mode Elections. Address mode is unregressed. No DB schema changes; the candidates-vs-politicians data-model gap is untouched.
</success_criteria>

<output>
After completion, create `.planning/quick/260426-dgb-essentials-elections-tab-should-work-for/SUMMARY.md` documenting:
- The new endpoint contract (request body, response shape, status codes).
- The extracted `getOverlappingGeoIdsForArea` helper and that `getPoliticiansByArea` was refactored to use it (no behavior change).
- The Results.jsx branching pattern for elections fetch.
- Confirmation that the candidates-vs-politicians data-model gap was NOT touched and remains a separate concern (project_candidates_vs_politicians memory).
</output>
