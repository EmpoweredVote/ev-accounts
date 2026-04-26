---
quick_id: 260426-dgb
type: summary
status: tasks-complete-checkpoint-pending
date: 2026-04-26
commits:
  - aacfbe4 (.claude monorepo) — feat(essentials-260426-dgb): add /browse/elections-by-area endpoint and overlap helper
  - c4a206c (essentials repo) — feat(essentials-260426-dgb): wire Elections tab to browse-mode endpoint
files_modified:
  - ev-accounts/backend/src/lib/essentialsBrowseService.ts
  - ev-accounts/backend/src/routes/essentialsBrowse.ts
  - essentials/src/lib/api.jsx
  - essentials/src/pages/Results.jsx
  - essentials/src/components/LocationBrowser.jsx
verification:
  - "ev-accounts/backend: npm run typecheck — PASS"
  - "essentials: npm run build — PASS"
  - "Manual checkpoint (browse-mode Elections tab in browser): PENDING — orchestrator will surface to user"
---

# Quick Task 260426-dgb — Essentials Elections Tab Works in Browse Mode

## Problem

Switching to the Elections tab in essentials' browse-by-location mode rendered an empty state. `Results.jsx` always called `fetchElectionsByAddress(activeQuery)`, but in browse mode `activeQuery` isn't a geocodable address — it's a label like "Los Angeles County, CA". The backend already had all primitives needed (PostGIS area intersection in `essentialsBrowseService` + `getElectionsByGeoIds` in `electionService`); they just weren't composed.

## Backend changes

### New helper: `getOverlappingGeoIdsForArea(geoId, mtfcc)`

`ev-accounts/backend/src/lib/essentialsBrowseService.ts`

```ts
export async function getOverlappingGeoIdsForArea(
  geoId: string,
  mtfcc: string
): Promise<{ geoIds: string[]; stateAbbrev: string | null }>;
```

Extracted from the existing intersection + state-resolution logic inside `getPoliticiansByArea`. Runs the same bidirectional PostGIS `ST_Contains` / `ST_Intersects` query against `essentials.geofence_boundaries`, prepends the input `geoId` to the result, then resolves the area's FIPS state code → 2-letter abbreviation via the existing `FIPS_TO_ABBREV` map.

`getPoliticiansByArea` was refactored to call this helper instead of duplicating the queries inline. Behavior is unchanged — the same `allGeoIds` array is fed to the politician query and the same `stateAbbrev` drives the statewide-officials supplemental query.

### New route: `POST /api/essentials/browse/elections-by-area`

`ev-accounts/backend/src/routes/essentialsBrowse.ts`

| Aspect             | Value                                                           |
| ------------------ | --------------------------------------------------------------- |
| Method             | POST                                                            |
| Auth               | `optionalAuth` (anonymous calls allowed)                        |
| Request body       | `{ geo_id: string, mtfcc: string }`                             |
| Validation errors  | `422 { code: 'VALIDATION_ERROR', message }` on missing inputs   |
| Server errors      | `500 { code: 'INTERNAL_ERROR', message: 'Failed to fetch ...' }`|
| Success status     | `200`                                                           |
| Success body       | `{ elections: ElectionResult[] }`                               |
| `X-Data-Status`    | `'no-geofence-data'` if `geoIds.length === 0`, else `'fresh'`   |

Body shape mirrors `/elections-by-address` so the existing frontend `setElectionsData(data.elections || [])` consumer "just works".

## Frontend changes

### New helper `fetchElectionsByArea(geoId, mtfcc)` — `essentials/src/lib/api.jsx`

Modeled on `fetchElectionsByAddress`. Uses `publicFetch` (same wrapper as `browseByArea`), POSTs `{ geo_id, mtfcc }`, returns `{ elections, error }` shape.

### Branched eager-fetch in `Results.jsx`

The Elections eager-fetch `useEffect` now branches on `searchMode`:

```jsx
useEffect(() => {
  if (electionsData !== null) return;
  let cancelled = false;

  if (searchMode === 'browse') {
    const geoId = browseArea?.geo_id || searchParams.get('browse_geo_id');
    const mtfcc = browseArea?.mtfcc || searchParams.get('browse_mtfcc');
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
    fetchElectionsByAddress(decodeURIComponent(activeQuery)).then((data) => { /* ... */ });
  }

  return () => { cancelled = true; };
}, [activeQuery, searchMode, browseArea?.geo_id, browseArea?.mtfcc]);
```

The reset effect was extended to the same dep set so `electionsData` clears whenever the active key (address OR browsed area) changes.

### `browseArea` state + LocationBrowser callback extension

A new `browseArea` state holds `{ geo_id, mtfcc }`. It is initialized from `?browse_geo_id` / `?browse_mtfcc` URL params (LA County and similar shortcut buttons), set by the shortcut effect when those params resolve, and set by the `LocationBrowser` callback when the user picks an area interactively. `LocationBrowser`'s `onResults` callback was extended from `(data, areaName, state)` to `(data, areaName, state, area)` where `area = { geo_id, mtfcc }` — backward-compatible since the new arg is positional and ignored by callers that don't need it.

## Data-model integrity

The candidates-vs-politicians data-model gap (per [project_candidates_vs_politicians.md](../../../) memory) was **NOT touched**. Elections data flows through `essentials.races` and `essentials.race_candidates` only. Candidates in the response include `is_incumbent`, `candidate_status`, and the optional `politician_id` link as already exposed by `getElectionsByGeoIds`. No `essentials.politicians` schema or query changes. No party-derived UI added in browse mode (`primary_party` on race is already handled by `ElectionsView` for primary races, antipartisan principle preserved).

## Verification

| Check                                                | Result |
| ---------------------------------------------------- | ------ |
| `cd ev-accounts/backend && npm run typecheck`        | PASS   |
| `cd essentials && npm run build`                     | PASS   |
| Manual browse-mode Elections render (LA County)      | PENDING — checkpoint surfaced by orchestrator |
| Manual browse-mode interactive (IN → Monroe County)  | PENDING — checkpoint surfaced by orchestrator |
| Manual address-mode regression (Bloomington address) | PENDING — checkpoint surfaced by orchestrator |

## Deviations

None. Plan executed as written. The LocationBrowser callback was extended (not "invented a new prop contract") because the plan explicitly said "if the interactive path does NOT push these params, also accept a fallback where we pass geoId/mtfcc through component state captured when the browse runs" — that fallback is the chosen path, with the callback signature extension being the cleanest way to surface `selectedArea` to `Results.jsx` without duplicating area state inside `LocationBrowser`.

## Notes for orchestrator

- The `essentials/` repo had pre-existing uncommitted modifications to `Results.jsx` (and other files) when this task ran. The Task 2 commit (`c4a206c`) bundles those pre-existing changes alongside the elections-tab wiring. This was unavoidable without `git stash` gymnastics on a sibling repo and matches the standing worktree state. Reviewers checking the elections-tab diff specifically should look for: imports of `fetchElectionsByArea`, `browseArea` state declaration, the branched useEffect, and the extended `LocationBrowser` `onResults` signature.
- Backend commit `aacfbe4` (`.claude` monorepo branch) shows `essentialsBrowse.ts` as `create mode 100644` — the file was untracked on the current branch though it exists upstream. The diff against the previous tracked version is purely additive (helper import + new route).
- Manual verification in the browser is the next step (the plan's `checkpoint:human-verify` Task 3); the executor stops here per orchestrator instructions.

## Self-Check: PASSED

- `ev-accounts/backend/src/lib/essentialsBrowseService.ts` — FOUND
- `ev-accounts/backend/src/routes/essentialsBrowse.ts` — FOUND
- `essentials/src/lib/api.jsx` — FOUND
- `essentials/src/pages/Results.jsx` — FOUND
- `essentials/src/components/LocationBrowser.jsx` — FOUND
- `.planning/quick/260426-dgb-essentials-elections-tab-should-work-for/260426-dgb-SUMMARY.md` — FOUND
- Commit `aacfbe4` in `.claude` monorepo (backend) — FOUND
- Commit `c4a206c` in `essentials` repo (frontend) — FOUND
