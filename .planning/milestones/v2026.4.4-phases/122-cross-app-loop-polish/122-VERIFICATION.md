---
phase: 122-cross-app-loop-polish
verified: 2026-04-17T00:00:00Z
status: human_needed
score: 5/6
overrides_applied: 0
human_verification:
  - test: "Confirm production evidence was captured per Task 3.3 and save screenshots/DOM snippets to .planning/phases/122-cross-app-loop-polish/evidence/"
    expected: "Seven evidence files saved: intg-01-prod/guest-arrival.png, intg-01-prod/guest-direct-revisit.png, intg-01-prod/authed-direct-revisit.png, intg-02-prod/ (picker cycle), intg-03-prod/treasury-cities.json, intg-03-prod/bloomington-cta.png, intg-03-prod/county-no-cta.png"
    why_human: "Production smoke requires a live browser session on essentials.empowered.vote and compass.empowered.vote with real user interaction (guest flow, auth flow, address search). Cannot be verified programmatically."
---

# Phase 122: Cross-App Loop Polish — Verification Report

**Phase Goal:** Close the three remaining voter-loop integration gaps (INTG-01, INTG-02, INTG-03) so the voter loop (Compass → Essentials profile with compass state hydrated → Treasury Tracker) works end-to-end on production.
**Verified:** 2026-04-17
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | A returning guest who previously calibrated the Compass and revisits an Essentials politician profile page (no #compass= fragment in URL) sees the CompassCard comparison overlay, not the Calibrate CTA. | VERIFIED | `CompassContext.jsx` line 127-143: when `answersResult.length === 0`, falls back to `loadGuestCompass()`, converts answers, sets `userAnswers`. `clearGuestCompass()` NOT called in this path. Commit `6b477a9` in essentials repo. |
| 2  | A returning logged-in user with empty API answers but a populated guestCompass localStorage entry still sees the overlay (D-14). | VERIFIED | Same fix as Truth 1 — the guard at line 127 (`if (answersResult.length === 0)`) covers the authed+empty-API case and falls back to guest cache. DEV probe at line 133 logs `priority=storage (authed+empty-api, guest cache fallback)`. |
| 3  | Every politician entry in the CompassV2 picker, when its 'View full profile on Essentials' link is clicked, opens an Essentials route that renders that politician's profile (INTG-02). | VERIFIED | `ComparePanel.jsx` line 120: `href={`${ESSENTIALS_URL}/politician/${politician.id}${serializeCompassFragment()}`}` — link construction already correct. INTG-02 closed evidence-only per D-07 (no code change needed). |
| 4  | On essentials.empowered.vote Results for a Bloomington, IN address, a 'Explore Bloomington revenue and expenses' CTA link appears below the Bloomington Common Council local-tier section and links to https://treasurytracker.empowered.vote/?entity=bloomington-in. | VERIFIED | `Results.jsx` line 940-977: `treasuryMatch = tier === 'Local' ? findMatchingMunicipality(body.title, treasuryCities) : null`; renders anchor with `href={`${TREASURY_URL}/?entity=${toTreasurySlug(treasuryMatch)}`}` and text `Explore {treasuryMatch.name} revenue and expenses`. `treasury.js` `findMatchingMunicipality` uses startsWith + longest-match strategy. `toTreasurySlug({name:'Bloomington', state:'IN'})` returns `bloomington-in`. |
| 5  | Local-tier sections whose body.title does not match a Treasury municipality with available_datasets>0 show NO CTA (no grayed-out state). | VERIFIED | `Results.jsx` line 962: `{treasuryMatch && (...)}` — CTA renders only when `treasuryMatch` is non-null. `findMatchingMunicipality` returns null when `available_datasets.length === 0` (line 70 in treasury.js) or when body title doesn't match. No disabled/grayed state rendered. |
| 6  | Production evidence (screenshots + DOM snippets) for each of the above is saved under .planning/phases/122-cross-app-loop-polish/evidence/ after Render deploy (D-13). | FAILED | `evidence/` directory does not exist. No screenshot or DOM files found. SUMMARY claimed "all 3 INTGs prod verified" but no evidence files were committed or placed on disk. |

**Score:** 5/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `essentials/src/lib/treasury.js` | `fetchTreasuryCities()`, `findMatchingMunicipality()`, `toTreasurySlug()` helpers | VERIFIED | File exists with all three named exports. `fetchTreasuryCities` wraps `apiFetch('/treasury/cities')`, returns `[]` on error. `toTreasurySlug` strips `/?#` chars (T-122-02). `findMatchingMunicipality` uses startsWith + has-data predicate + longest-name-wins + entity-type-word rejection. |
| `essentials/src/pages/Results.jsx` | Treasury CTA rendered below each matched local-tier GovernmentBodySection | VERIFIED | Imports all three helpers at line 19. `useState([])` for `treasuryCities` at line 268. One-shot `useEffect` at line 269. CTA render at lines 940-977 inside `bodies.map`, after `</GovernmentBodySection>`. Contains "Explore" text at line 971. |
| `essentials/src/contexts/CompassContext.jsx` | Fixed guest-priority chain; dev-mode probe log | VERIFIED | Lines 127-151: guard added so `clearGuestCompass()` only fires when `answersResult.length > 0`. Lines 132-143: guest cache fallback branch when authed+empty-API. DEV probe logs at lines 133, 140, 147, 156, 169, 176 — all gated behind `import.meta.env.DEV`. |
| `essentials/.env.example` | Documents `VITE_TREASURY_URL` default | VERIFIED | File contains `VITE_TREASURY_URL=https://treasurytracker.empowered.vote` on line 2. |
| `ev-accounts/tests/integration/treasury-cities.test.ts` | Vitest contract test locking /api/treasury/cities response shape | VERIFIED | File exists at correct path. Tests: (1) 200 + array, (2) required keys `id, name, state, available_datasets` per entry, (3) `available_datasets` is an array. Shape-only assertions tolerate empty list. Commit `5438ece` in ev-accounts. Note: PLAN specified path `ev-accounts/backend/tests/treasury.cities.contract.test.ts` — actual path is `ev-accounts/tests/integration/treasury-cities.test.ts`. Functionally equivalent; different integration test layout. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `essentials/src/contexts/CompassContext.jsx` | `essentials/src/lib/compass.js :: loadGuestCompass` | guest-priority fallback when authed answers are empty | WIRED | `loadGuestCompass` imported at line 11, called at line 130 inside `if (answersResult.length === 0)` branch. |
| `essentials/src/pages/Results.jsx` | `/api/treasury/cities` | `fetchTreasuryCities()` in useEffect on mount | WIRED | `fetchTreasuryCities` imported from `../lib/treasury` at line 19, called in `useEffect(() => { fetchTreasuryCities().then(setTreasuryCities); }, [])` at line 269. |
| `essentials/src/pages/Results.jsx` | `treasurytracker.empowered.vote` | anchor href built from `VITE_TREASURY_URL` + `toTreasurySlug(match)` | WIRED | `TREASURY_URL = import.meta.env.VITE_TREASURY_URL || 'https://treasurytracker.empowered.vote'` at line 21. Href at line 965: `${TREASURY_URL}/?entity=${toTreasurySlug(treasuryMatch)}`. |
| `CompassV2/src/components/ComparePanel.jsx` | `essentials/src/pages/Profile.jsx (via /politician/:id)` | `serializeCompassFragment()` appended to link href | WIRED | Line 120: `href={`${ESSENTIALS_URL}/politician/${politician.id}${serializeCompassFragment()}`}`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|--------------------|--------|
| `essentials/src/pages/Results.jsx` (Treasury CTA) | `treasuryCities` | `fetchTreasuryCities()` → `apiFetch('/treasury/cities')` → `GET /api/treasury/cities` | Yes — real DB query via `treasuryService.getCities()` (existing backend route) | FLOWING |
| `essentials/src/contexts/CompassContext.jsx` (guest fallback) | `userAnswers` | `loadGuestCompass()` → `localStorage.getItem('guestCompass')` → `convertGuestAnswersToApiFormat()` | Yes — reads from localStorage populated by CompassV2 fragment relay | FLOWING |

### Behavioral Spot-Checks

Step 7b: SKIPPED for guest/auth flows and production URL checks — requires a live browser session. Build-level checks performed instead.

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `treasury.js` exports are importable | File exists with correct export keywords | `fetchTreasuryCities`, `toTreasurySlug`, `findMatchingMunicipality` all exported | PASS |
| `toTreasurySlug({name:'Bloomington', state:'IN'})` returns `bloomington-in` | Code inspection | `name.toLowerCase().replace(/\s+/g, '-') + '-' + state.toLowerCase()` = `bloomington-in` | PASS |
| `findMatchingMunicipality` returns null for `available_datasets.length === 0` | Code inspection | Line 70: `if (!c.available_datasets || c.available_datasets.length === 0) return false` | PASS |
| Contract test file exists with shape assertions | File read | `ev-accounts/tests/integration/treasury-cities.test.ts` — checks `id, name, state, available_datasets` keys | PASS |
| DEV probe gated behind `import.meta.env.DEV` | Code inspection | All 6 probe log lines (132, 140, 146, 156, 169, 176) wrapped in `if (import.meta.env.DEV)` | PASS |
| `clearGuestCompass()` not called when authed+empty-API | Code inspection | Line 127-143: `if (answersResult.length === 0)` enters guest cache branch; `clearGuestCompass()` NOT called there. Called only at line 143 (no guest cache) and line 150 (has API answers). | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| INTG-01 | 122-01-PLAN.md | CompassCard state relay works correctly across app boundaries | SATISFIED | `CompassContext.jsx` fix: authed+empty-API falls back to guest cache; never wipes guest data prematurely. |
| INTG-02 | 122-01-PLAN.md | Compass compare page links to Essentials politician profiles | SATISFIED | `ComparePanel.jsx` link construction already correct — closed evidence-only per D-07. |
| INTG-03 | 122-01-PLAN.md | Essentials→Treasury handoff functional | SATISFIED | `treasury.js` helpers + `Results.jsx` CTA wired and rendering per code inspection. |

All three REQUIREMENTS.md Phase 122 IDs accounted for. No orphaned requirements.

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `essentials/src/contexts/CompassContext.jsx` | DEV probe `console.log` calls at lines 133, 140, 147, 156, 169, 176 | Info | All gated behind `import.meta.env.DEV` — production builds strip these via Vite tree-shaking. Not a blocker. |

No stubs, no placeholder returns, no hardcoded empty data passed to rendering components.

### Threat Model Verification

| Threat ID | Disposition | Verified |
|-----------|-------------|---------|
| T-122-01 | mitigate | VERIFIED — `parseCompassFragment` wraps `JSON.parse(atob(...))` in try/catch (line 118); checks `typeof decoded !== 'object'` (line 126); validates `decoded.a` is object and `decoded.s` is array (lines 137-139). |
| T-122-02 | mitigate | VERIFIED — `toTreasurySlug` strips `/?#` chars (treasury.js lines 32, 35); CTA anchor has `target="_blank" rel="noopener noreferrer"` (Results.jsx lines 967-968); URL built from API-sourced data only, not user input. |
| T-122-03 | accept | Accepted — guestCompass contains stance positions + topic UUIDs, no PII. |
| T-122-04 | accept (evidence) | `extractHashToken` only fires when hash contains `access_token=` (auth.js line 22); `parseCompassFragment` checks for `#compass=` prefix (compass.js line 120) — mutually exclusive conditions, no hash race. |
| T-122-05 | accept | Single fetch per mount via `useEffect([], [])` — no amplification. |

### Human Verification Required

The following item cannot be verified programmatically and requires human action:

#### 1. Production Evidence Capture (Task 3.3)

**Test:** After confirming Render has deployed with `VITE_TREASURY_URL` set on the Essentials service, run the full production smoke script from SUMMARY.md §"Checkpoint 3.3":
1. `curl https://api.empowered.vote/api/treasury/cities | jq '.[0] | keys'` — confirm `id, name, state, available_datasets` present. Save to `evidence/intg-03-prod/treasury-cities.json`.
2. On compass.empowered.vote as guest, answer a topic, click "View full profile on Essentials" for Pierce. Screenshot → `evidence/intg-01-prod/guest-arrival.png`.
3. Close tab. Revisit `https://essentials.empowered.vote/politician/72dd5219-490f-48bb-986e-183a6098d602` directly. Confirm CompassCard overlay still renders. Screenshot → `evidence/intg-01-prod/guest-direct-revisit.png`.
4. Log in, repeat step 3. Screenshot → `evidence/intg-01-prod/authed-direct-revisit.png` (D-14).
5. Cycle all picker entries on compass.empowered.vote. Confirm all resolve. Evidence → `evidence/intg-02-prod/`.
6. Enter a Bloomington IN address on essentials.empowered.vote. Screenshot CTA under Bloomington Common Council → `evidence/intg-03-prod/bloomington-cta.png`. Click it — confirm Treasury Tracker loads `/?entity=bloomington-in`. Screenshot → `evidence/intg-03-prod/treasury-landing.png`.
7. Confirm NO CTA under Monroe County Government. Screenshot → `evidence/intg-03-prod/county-no-cta.png`.

**Expected:** All seven evidence files saved to `.planning/phases/122-cross-app-loop-polish/evidence/`.

**Why human:** Cross-origin fragment relay, localStorage state, and production URL behavior require a live browser session. The evidence directory is absent — no screenshots or DOM dumps exist on disk despite the SUMMARY claiming production verification complete.

**Note on `VITE_TREASURY_URL`:** The PLAN `user_setup` section requires setting `VITE_TREASURY_URL=https://treasurytracker.empowered.vote` as a build-time env var on the Essentials Render service. Verify this was done before triggering evidence capture — if the env var is not set, the production default in code (`https://treasurytracker.empowered.vote`) will still work, but the intent is to have it explicitly configured.

### Gaps Summary

One gap blocking full closure: the production evidence directory is absent. The code changes for all three INTG requirements are fully implemented, substantive, and wired per code inspection. All automated verifications pass. The single outstanding item is that Task 3.3 (production smoke + evidence capture) was marked complete in the SUMMARY but no evidence files exist on disk under `evidence/`.

This is a documentation/artifact gap, not a code gap — the implementation is complete. The must-have explicitly required evidence be saved. To close: run the production smoke steps above and save the resulting screenshots to the `evidence/` subdirectories.

---

_Verified: 2026-04-17T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
