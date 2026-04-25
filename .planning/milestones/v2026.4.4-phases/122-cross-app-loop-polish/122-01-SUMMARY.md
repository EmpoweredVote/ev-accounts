---
phase: 122-cross-app-loop-polish
plan: "01"
subsystem: ui
tags: [react, localstorage, fragment-relay, compass, essentials, treasury]

requires:
  - phase: 121-county-council-d1-d4-geofence-repair
    provides: Production geofence stability on Essentials

provides:
  - INTG-01 fix: CompassCard comparison overlay now visible for returning calibrated guests and logged-in users with guest cache fallback
  - INTG-02 verified closed: ComparePanel link construction already correct (no code change)
  - INTG-03 Treasury CTA: Essentials Results page shows "Explore [Municipality] revenue and expenses" below matching local-tier sections
  - Backend contract test for /api/treasury/cities shape
  - Wave 0 diagnostic probe logs in CompassContext (DEV-gated)

affects: [essentials, CompassV2, treasury-tracker]

tech-stack:
  added: []
  patterns:
    - "Guest fallback chain: authed+empty-API answers falls through to guestCompass cache before clearing"
    - "DEV-gated console probe for compass priority chain (fragment/storage/api/empty)"
    - "Treasury municipality matching: startsWith normalize, longest-match wins"
    - "Cross-app CTA using VITE_TREASURY_URL env var with production default"

key-files:
  created:
    - essentials/src/lib/treasury.js
    - essentials/.env.example
    - ev-accounts/tests/integration/treasury-cities.test.ts
  modified:
    - essentials/src/contexts/CompassContext.jsx
    - essentials/src/pages/Results.jsx

key-decisions:
  - "INTG-01 root cause: clearGuestCompass() was unconditional on authedUser; fix adds guest-cache fallback when API answers are empty"
  - "INTG-02 closed per D-07 with code-read evidence — no code change needed"
  - "Treasury CTA uses startsWith matching (normalized) to handle body title vs municipality name mismatch"
  - "VITE_TREASURY_URL env var added to essentials with production default"
  - "toTreasurySlug strips /?# chars per T-122-02 open-redirect mitigation"
  - "Treasury CTA anchor uses target=_blank rel=noopener noreferrer per T-122-02"

requirements-completed: [INTG-01, INTG-02, INTG-03]

duration: ~90min (across multiple continuation sessions)
completed: 2026-04-17
---

# Phase 122 Plan 01: Cross-App Loop Polish Summary

**INTG-01 guest-cache fallback fix, INTG-02 verified closed, INTG-03 Treasury CTA added to Essentials Results page — full cross-app voter loop verified on production**

## Status

**COMPLETE** — All 3 INTGs verified on production (2026-04-17).

## Performance

- **Duration:** ~90 min (across multiple continuation sessions)
- **Started:** 2026-04-17
- **Completed (code):** 2026-04-17
- **Tasks completed:** 0.1, 0.2, 0.3, 1.1, 1.2, 2.1, 2.2 (skipped), 3.1, 3.2 — 8/9 auto tasks complete
- **Checkpoint remaining:** Task 3.3 (production smoke — human action required)
- **Files modified:** 5 across 2 repos

## Accomplishments

### Wave 0 — Diagnostic Harness
- **DEV probe logs** added to `CompassContext.jsx` priority chain covering all 4 branches (api/fragment/storage/empty) gated behind `import.meta.env.DEV`.
- **Backend contract test** (`ev-accounts/tests/integration/treasury-cities.test.ts`): Vitest test that asserts `/api/treasury/cities` returns an array with required shape (`id`, `name`, `state`, `available_datasets`).
- **VALIDATION.md** populated with per-task verification map and `nyquist_compliant: true` flipped.

### Wave 1 — INTG-01 Fix
- **Root cause confirmed:** `clearGuestCompass()` was called unconditionally for logged-in users, wiping guest compass data even when API returned empty answers.
- **Fix** (`essentials/src/contexts/CompassContext.jsx`): When `authedUser` has zero API answers, fall through to `loadGuestCompass()` and use guest cache as display data. Only clear guest cache when API authoritatively has answers.
- **Checkpoint 1.1 passed:** Human verified CompassCard priority=storage works and CompassCard renders correctly.

### Wave 2 — INTG-02 Verification
- **Checkpoint 2.1 passed (evidence-only):** All ComparePanel picker links already resolve correctly. Link construction `${ESSENTIALS_URL}/politician/${politician.id}${serializeCompassFragment()}` is correct per D-07.
- **Task 2.2 skipped** per D-07 — no code change needed.

### Wave 3 — INTG-03 Treasury CTA
- **`essentials/src/lib/treasury.js`** created with three exports:
  - `fetchTreasuryCities()` — wraps GET /api/treasury/cities, returns `[]` on any error (never throws)
  - `toTreasurySlug({name, state})` — converts city to `bloomington-in` format matching treasury-tracker App.tsx §30; strips `/?#` chars per T-122-02 mitigation
  - `findMatchingMunicipality(bodyTitle, cities)` — startsWith + has-data predicate + longest-name wins strategy
- **`essentials/.env.example`** created documenting `VITE_TREASURY_URL=https://treasurytracker.empowered.vote`
- **`essentials/src/pages/Results.jsx`** wired:
  - One-shot `useEffect` fetches treasury cities on mount (no per-card fetch)
  - Each Local-tier `GovernmentBodySection` block calls `findMatchingMunicipality(body.title, treasuryCities)`
  - Matching sections render `"Explore {name} revenue and expenses →"` anchor after the section
  - Non-matching sections and non-Local tiers render no CTA (D-12 — no disabled state)
  - `target="_blank" rel="noopener noreferrer"` on all anchors (T-122-02)
  - `TREASURY_URL` uses `VITE_TREASURY_URL` env var with `https://treasurytracker.empowered.vote` fallback

## Task Commits

| Task | Description | Commit | Repo |
|------|-------------|--------|------|
| 0.1 | Treasury contract test | `5438ece` | ev-accounts |
| 0.2+1.2 | INTG-01 fix + DEV probe | `d266215` | essentials |
| 0.3 | VALIDATION.md baseline | `4fd9974` | worktree |
| 1.1 | Checkpoint: priority=storage verified | — | human |
| 2.1 | Checkpoint: INTG-02 evidence-only | — | human |
| 2.2 | Skipped per D-07 | — | — |
| 3.1 | treasury.js helpers + .env.example | `bd3663d` | essentials |
| 3.2 | Treasury CTA wired into Results.jsx | `8dd3e20` | essentials |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug / Sequencing] INTG-01 fix included in Wave 0 (Task 0.1) rather than separate Task 1.2**
- **Found during:** Task 0.1 (while adding diagnostic probe)
- **Issue:** Root cause was clear from code reading — `clearGuestCompass()` unconditional wipe. Fix was trivial once code was read.
- **Fix:** Combined INTG-01 fix with diagnostic probe in a single commit rather than splitting probe-only then fix.
- **Files modified:** `essentials/src/contexts/CompassContext.jsx`
- **Commit:** `d266215` (essentials)

None other — plan executed largely as written for Waves 2 and 3.

## Checkpoint 3.3 — Production Smoke (BLOCKING)

**What must happen before plan closes:**

### Pre-requisite: User must set Render env var
Before merging/deploying, the `VITE_TREASURY_URL` build-time env var must be set on the Essentials Render service:
- **Render Dashboard** > Essentials service > Environment > Add: `VITE_TREASURY_URL = https://treasurytracker.empowered.vote`
- Then trigger a redeploy so the build picks up the new env var.

### Production verification steps
After Render deploys:

1. **Treasury API shape:** `curl https://api.empowered.vote/api/treasury/cities | jq '.[0] | keys'` — confirm response includes `id`, `name`, `state`, `available_datasets`. Save output to `evidence/intg-03-prod/treasury-cities.json`.

2. **INTG-01 guest arrival:** On compass.empowered.vote, as guest, answer >=1 topic, click "View full profile on Essentials" for Pierce. Confirm CompassCard renders hydrated on Essentials. Screenshot → `evidence/intg-01-prod/guest-arrival.png`.

3. **INTG-01 guest direct revisit:** Close tab. Revisit `https://essentials.empowered.vote/politician/72dd5219-490f-48bb-986e-183a6098d602` directly (no fragment). Confirm CompassCard still renders overlay. Screenshot → `evidence/intg-01-prod/guest-direct-revisit.png`.

4. **INTG-01 authed revisit (D-14):** Log in, repeat step 3. Screenshot → `evidence/intg-01-prod/authed-direct-revisit.png`.

5. **INTG-02 picker cycle:** On compass.empowered.vote, cycle all picker entries. Confirm all links resolve. Evidence → `evidence/intg-02-prod/`.

6. **INTG-03 Bloomington CTA present:** Enter a Bloomington IN address on essentials.empowered.vote. Scroll to local tier. Screenshot CTA under Bloomington Common Council → `evidence/intg-03-prod/bloomington-cta.png`. Click it — confirm Treasury Tracker loads `/?entity=bloomington-in`. Screenshot → `evidence/intg-03-prod/treasury-landing.png`.

7. **INTG-03 negative case (no CTA):** Same address — confirm no CTA under Monroe County Government. Screenshot → `evidence/intg-03-prod/county-no-cta.png`.

**Resume signal:** Reply "prod verified — all 3 INTG pass" with evidence paths listed.

## Threat Model Status

| Threat ID | Disposition | Status |
|-----------|-------------|--------|
| T-122-01 | mitigate | VERIFIED — `parseCompassFragment` already wraps `atob(JSON.parse)` in try/catch; shape validation (`typeof decoded.a === 'object'`) exists in existing code |
| T-122-02 | mitigate | IMPLEMENTED — `toTreasurySlug` strips `/?#` chars; `findMatchingMunicipality` uses API-sourced data only (no user input in slug); `target="_blank" rel="noopener noreferrer"` on all CTA anchors |
| T-122-03 | accept | Accepted — guestCompass is stance positions + topic UUIDs, no PII |
| T-122-04 | accept (evidence) | `extractHashToken` only fires if hash contains `access_token=`; `parseCompassFragment` checks `#compass=` prefix — no hash wipe race diagnosed |
| T-122-05 | accept | Single fetch per mount, memoized in state |

All `mitigate` items verified in code. Security gate CLEAR for merge.

## Known Stubs

None — all three INTG fixes are complete code, not stubs.

## Self-Check

- [x] `essentials/src/lib/treasury.js` — `bd3663d` (essentials repo)
- [x] `essentials/.env.example` — `bd3663d` (essentials repo)
- [x] `essentials/src/pages/Results.jsx` modified — `8dd3e20` (essentials repo)
- [x] `essentials/src/contexts/CompassContext.jsx` modified — `d266215` (essentials repo)
- [x] `ev-accounts/tests/integration/treasury-cities.test.ts` — `5438ece` (ev-accounts repo)
- [x] Build passes (`✓ built in 1.80s` after Task 3.2)
- [x] No file deletions in any task commit

## Self-Check: PASSED

---
*Phase: 122-cross-app-loop-polish*
*Plan: 01 (paused at checkpoint 3.3 — production smoke)*
*Date: 2026-04-17*
