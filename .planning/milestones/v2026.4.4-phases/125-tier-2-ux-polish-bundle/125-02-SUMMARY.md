---
phase: 125-tier-2-ux-polish-bundle
plan: "02"
subsystem: ui
tags: [react, sql, postgresql, coalesce, localstorage, cross-app, geo-default]

# Dependency graph
requires:
  - phase: 125-01
    provides: essentials Wave 1 UX polish (toAddressTitleCase, eager elections fetch)
  - phase: 122-cross-app-loop-polish
    provides: GUEST_COMPASS_KEY cross-app localStorage bridge pattern

provides:
  - NULLIF-wrapped COALESCE in compassService SQL fixing Pierce headshot (G-114-014)
  - USER_ADDRESS_KEY + saveUserAddress/loadUserAddress/clearUserAddress bridge in essentials
  - essentials Results.jsx writes evUserAddress on every successful address search
  - CompassV2 InlinePoliticianPicker reads evUserAddress and pre-selects state filter (G-114-011 Tier 1)

affects: [125-03-readrank-treasury-wave]

# Tech tracking
tech-stack:
  added:
    - vitest (essentials dev dependency — added to support compass.address.test.js)
  patterns:
    - NULLIF(col, '') inside COALESCE chains to prevent empty-string short-circuit
    - evUserAddress localStorage bridge — separate namespaced key for cross-app address context
    - One-shot useEffect with availableStates dependency for geo-default in Compass picker

key-files:
  created:
    - essentials/src/lib/compass.address.test.js
  modified:
    - ev-accounts/backend/src/lib/compassService.ts
    - ev-accounts/tests/integration/compass.test.ts
    - essentials/src/lib/compass.js
    - essentials/src/pages/Results.jsx
    - essentials/package.json
    - CompassV2/src/components/InlinePoliticianPicker.jsx

key-decisions:
  - "G-114-014: NULLIF wraps applied to photo_custom_url and photo_origin_url only — audit of other COALESCE patterns deferred as post-phase quick-task per RESEARCH Q4"
  - "G-114-011 Tier 1: separate key 'evUserAddress' chosen over extending GUEST_COMPASS_KEY — separation of concerns per RESEARCH recommendation (b)"
  - "G-114-011 Tier 2 (browser geolocation): intentionally deferred — Tier 1 + Tier 3 cover common case without new backend surface area"
  - "vitest added to essentials dev deps — minimal install, no disruption to Vite build"

patterns-established:
  - "evUserAddress localStorage bridge: { addr, state (USPS 2-letter), ts (epoch ms) } — 30-day TTL, try/catch on all read/write paths"
  - "NULLIF-COALESCE pattern: always wrap potentially-empty string columns with NULLIF(col, '') inside COALESCE to prevent empty strings winning over real values"

requirements-completed: [UX-01]

# Metrics
duration: 15min
completed: 2026-04-17
---

# Phase 125 Plan 02: Compass UX Polish (Wave 2) Summary

**SQL NULLIF fix for Matt Pierce headshot in Compass compare panel, plus cross-app localStorage address bridge enabling geo-aware state pre-selection in the compare picker**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-04-17T21:02:00Z
- **Completed:** 2026-04-17T21:17:00Z
- **Tasks:** 2 of 3 complete (Task 3 is a human-verify checkpoint — awaiting production verification)
- **Files modified:** 6 (plus 1 new test file)

## Accomplishments

- G-114-014: Fixed the SQL COALESCE empty-string bug in `getCompassPoliticians` — NULLIF wraps on `photo_custom_url` and `photo_origin_url` ensure that `photo_origin_url = ''` no longer short-circuits the fallthrough to `essentials.politician_images.url`
- G-114-011 Tier 1: Added `USER_ADDRESS_KEY`, `saveUserAddress`, `loadUserAddress`, `clearUserAddress` to `essentials/src/lib/compass.js` following the established GUEST_COMPASS_KEY pattern
- G-114-011 Tier 1: `Results.jsx` now parses the 2-letter state code from `formattedAddress` and writes `evUserAddress` to localStorage on every successful address search
- G-114-011 Tier 1: `InlinePoliticianPicker.jsx` (CompassV2) reads `evUserAddress` on mount and pre-selects `stateFilter` when user has not already chosen one and `availableStates` contains the saved state — Tier 3 (unfiltered) is preserved as default when no address context exists
- Added 8-test vitest suite in essentials for the address bridge functions (all passing)

## Task Commits

Each task was committed atomically in the relevant sub-repo:

1. **Task 1: G-114-014 NULLIF-wrap COALESCE** - `6134782` (fix) in ev-accounts `feat/125-compass-ux-polish`
2. **Task 2: G-114-011 Tier 1 address bridge (essentials)** - `50febe8` (feat) in essentials `feat/125-compass-ux-polish`
3. **Task 2: G-114-011 Tier 1 address bridge (CompassV2)** - `1b552bd` (feat) in CompassV2 `feat/125-compass-ux-polish`
4. **Task 3: Production verification** - PENDING (human-verify checkpoint)

## Files Created/Modified

- `ev-accounts/backend/src/lib/compassService.ts` — Line ~273: COALESCE changed to `COALESCE(NULLIF(p.photo_custom_url, ''), NULLIF(p.photo_origin_url, ''), pi.url, '')` with inline comment referencing G-114-014
- `ev-accounts/tests/integration/compass.test.ts` — Added source-level regression test verifying NULLIF strings are present in compassService.ts
- `essentials/src/lib/compass.js` — Appended `USER_ADDRESS_KEY`, `saveUserAddress`, `loadUserAddress`, `clearUserAddress` exports after existing bridge functions
- `essentials/src/lib/compass.address.test.js` — NEW: 8 unit tests for address bridge functions (round-trip, TTL, missing key, malformed JSON, clearUserAddress, guard cases)
- `essentials/src/pages/Results.jsx` — Added `saveUserAddress` import; extended `formattedAddress` sync effect to parse state and call `saveUserAddress`
- `essentials/package.json` — Added `vitest` dev dependency and `"test": "vitest run"` script
- `CompassV2/src/components/InlinePoliticianPicker.jsx` — Added cross-app contract comment at file top; added one-shot geo-default `useEffect` after hydration effect

## Decisions Made

- Applied NULLIF wraps only to `photo_custom_url` and `photo_origin_url` in `getCompassPoliticians`. Broader audit of other COALESCE patterns in the codebase is filed as a post-phase follow-up (per RESEARCH Q4 scope limit).
- Used separate `evUserAddress` key rather than extending `GUEST_COMPASS_KEY` — separation of concerns: compass quiz state belongs in its own key, address context belongs in its own key.
- Tier 2 (browser geolocation) intentionally omitted per RESEARCH Q3 resolution and CONTEXT deferred section. Tier 1 (Essentials localStorage) covers the primary user path.
- Regression test for G-114-014 is a source-level check rather than a DB-level test — full DB test requires live Supabase connection not available in CI. Comment in test explains the rationale.

## Deviations from Plan

**1. [Rule 2 - Missing Critical] TTL test used past timestamp instead of ttlMs:0**
- **Found during:** Task 2 (running tests)
- **Issue:** `loadUserAddress({ ttlMs: 0 })` returns `null` only when `Date.now() - ts > 0`, but a freshly-saved entry has `ts ≈ Date.now()`, making the difference 0ms which is not `> 0`. Test passed a valid entry.
- **Fix:** Changed TTL test to store an entry with `ts = Date.now() - 31 days` and use default 30-day TTL — correctly exercises the expiry path.
- **Files modified:** `essentials/src/lib/compass.address.test.js`
- **Committed in:** `50febe8`

---

**Total deviations:** 1 auto-fixed (Rule 2 — test correctness)
**Impact on plan:** Trivial; test now correctly exercises TTL expiry path. No scope creep.

## Issues Encountered

None during implementation. Wave 1 G-114-004 (cross-reference annotation) was reverted after merge (commit `a422728` in essentials), but that is out of scope for Wave 2 — Wave 2 only covers G-114-011 and G-114-014.

## User Setup Required

**Wave 2 requires merging three feature branches to trigger Render auto-deploy:**

1. `ev-accounts`: PR from `feat/125-compass-ux-polish` → `master`
   - URL: https://github.com/EmpoweredVote/ev-accounts/compare/feat/125-compass-ux-polish
2. `essentials`: PR from `feat/125-compass-ux-polish` → `main`
   - URL: https://github.com/EmpoweredVote/essentials/compare/feat/125-compass-ux-polish
3. `CompassV2`: PR from `feat/125-compass-ux-polish` → `main`
   - URL: https://github.com/EmpoweredVote/CompassV2/compare/feat/125-compass-ux-polish

After all three Render services redeploy, run Task 3 production verification:

**G-114-014 API check:**
```
curl -s https://api.empowered.vote/api/compass/politicians | jq '.[] | select(.last_name=="Pierce") | {first_name, last_name, photo_origin_url}'
```
Expected: `photo_origin_url` is a non-empty Supabase CDN URL.

**G-114-014 UI check:** Open https://compass.empowered.vote, navigate to compare picker, find Matt Pierce — headshot should render (not silhouette/placeholder).

**G-114-011 UI check:**
1. Open https://essentials.empowered.vote in incognito
2. Search "200 W Kirkwood Ave, Bloomington, IN"
3. In same browser session, open https://compass.empowered.vote
4. Open compare picker — "IN" (Indiana) should be pre-selected in state filter dropdown
5. Control: clear localStorage (`localStorage.removeItem('evUserAddress')`) and reload Compass — picker should show unfiltered (Tier 3), NOT pre-select Indiana

## Next Phase Readiness

- Wave 2 code complete on branches `feat/125-compass-ux-polish` in all three repos
- Wave 3 (Read & Rank + Treasury: G-114-020, G-114-021, G-114-023, G-114-024, G-114-025) may begin once Task 3 production checkpoint is approved per D-09
- No blockers on Wave 3 code — it is independent of Wave 2 changes

## Known Stubs

None — both gaps (G-114-014 and G-114-011 Tier 1) are fully wired. The evUserAddress bridge is live code that runs on every address search; the InlinePoliticianPicker reads it on mount. No placeholder data.

## Post-Phase Follow-ups

- **COALESCE audit:** Grep `ev-accounts/backend/src` for `COALESCE(.*photo_.*url.*)` patterns and apply same NULLIF wrapping per RESEARCH Q4 recommendation. File as a Tier 2 quick-task.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes introduced. All changes are frontend state reads/writes and a backend SQL expression change within an existing query.

## Self-Check: PASSED

- `ev-accounts/backend/src/lib/compassService.ts`: FOUND
- NULLIF(p.photo_custom_url, ''): FOUND in compassService.ts
- NULLIF(p.photo_origin_url, ''): FOUND in compassService.ts
- `essentials/src/lib/compass.js` USER_ADDRESS_KEY: FOUND
- `essentials/src/lib/compass.address.test.js`: FOUND (8 tests pass)
- `essentials/src/pages/Results.jsx` saveUserAddress: FOUND
- `CompassV2/src/components/InlinePoliticianPicker.jsx` evUserAddress: FOUND
- ev-accounts commit 6134782: FOUND
- essentials commit 50febe8: FOUND
- CompassV2 commit 1b552bd: FOUND

---
*Phase: 125-tier-2-ux-polish-bundle*
*Completed: 2026-04-17 (Task 3 human-verify checkpoint pending)*
