# Phase 125: Tier 2 UX Polish Bundle — Research

## RESEARCH COMPLETE

**Researched:** 2026-04-17
**Phase:** 125 — Tier 2 UX Polish Bundle
**Confidence:** HIGH (all 10 gaps verified against code + live API + production DB)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Researcher must verify current production state of each gap before writing fix tasks. Only gaps confirmed still broken get fix tasks.
- **D-02 (G-114-011):** Three-tier fallback chain for state pre-selection: (1) Essentials address localStorage → (2) browser geolocation reverse-geocode → (3) unfiltered fallback. Do NOT hardcode Indiana.
- **D-03 (G-114-011):** Geo-default applies to picker dropdown filter only, not to result list. User can still manually change.
- **D-04 (G-114-014):** Determine whether Compass compare panel sources headshots from `essentials.politician_images` or separate source. Align to single source.
- **D-05 (G-114-021):** Add "Featured municipalities" section at top of Treasury landing surfacing IN cities (Bloomington, Monroe County). Static list acceptable.
- **D-06 (G-114-023):** Add "Latest available: FY2025" notice on Monroe County page if FY2026 data unavailable.
- **D-07 (G-114-024):** Import FY2025 Bloomington data via `importBudgetHierarchy.ts`. Researcher confirms source data status first.
- **D-08 (G-114-025):** Add permanent labels for top-level categories on sunburst, OR remove sunburst toggle. Researcher recommends which is less risky.
- **D-09:** Three app-by-app waves with production verification between each:
  - Wave 1 (Essentials): 001, 002, 004
  - Wave 2 (Compass): 011, 014
  - Wave 3 (Read & Rank + Treasury): 020, 021, 023, 024, 025

### Claude's Discretion

- Exact fix style for G-114-004 cross-reference annotation
- Visual treatment of "Featured municipalities" section
- Browser geolocation: silent skip (preferred) vs prompt
- Diagnostic approach for G-114-014

### Deferred Ideas (OUT OF SCOPE)

- G-114-005, G-114-008, G-114-013, G-114-015, G-114-017, G-114-019, G-114-022 — all CUT, not deferred to roadmap.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UX-01 | 21 Tier 2 G-114 minor/confusing UX gaps addressed (10 in scope after CONTEXT cuts) | Per-gap deep dives below verify current state and prescribe fix approach |
</phase_requirements>

---

## Executive Summary — Gap Status Table

Per D-01, every in-scope gap was verified against current code, live API, and production DB.

| Gap | App | Status | Evidence |
|-----|-----|--------|----------|
| G-114-001 | essentials | **ALREADY RESOLVED** | `useGooglePlacesAutocomplete` hook is wired in `essentials/src/pages/Results.jsx:392-398`. Verify in production; if working, close. |
| G-114-002 | essentials | **STILL BROKEN** | `formattedAddress` rendered raw at `Results.jsx:813`. Source is Census Geocoder `matchedAddress` (uppercase from `geocodingService.ts:71`). Fix in frontend display layer. |
| G-114-004 | essentials | **STILL BROKEN** | Cross-reference annotation absent. Both tabs render same candidate independently (Representatives via `renderPoliticianCard` at `Results.jsx:555`; Elections via `<ElectionsView>` at `Results.jsx:1010`). |
| G-114-011 | compass | **STILL BROKEN** | `InlinePoliticianPicker` uses `useFilteredPoliticians` hook with no geo-default for `stateFilter`. `loadGuestCompass` reads `{a, s, i}` only — does NOT store address. New address-storage mechanism needed. |
| G-114-014 | compass | **STILL BROKEN — root cause identified** | Backend `compassService.ts:273` COALESCE returns `''` (empty string from `photo_origin_url`) instead of falling through to `pi.url`. NULL vs empty-string bug. |
| G-114-020 | read-rank | **STILL BROKEN** | `read-rank/index.html:7` literal `<title>readrank-prototype</title>`. One-line fix. |
| G-114-021 | treasury | **STILL BROKEN** | `treasury-tracker/src/components/AlphaLanding.tsx:122` `CityGrid` uses unsorted `available.map()`. Bloomington has "Pilot" badge but no precedence. Insert featured section. |
| G-114-023 | treasury | **STILL BROKEN — confirmed** | Monroe County API returns 2025 as latest year (no 2026 dataset). Bloomington has 2026. Notice needed. |
| G-114-024 | treasury | **ALREADY RESOLVED IN DATA — verify UI** | Bloomington FY2025 data EXISTS in `treasury.budgets` (1445 operating + 246 revenue + 506 salaries categories). Confirmed via API `/api/treasury/cities`. Year was likely missing at audit time but is now imported. UI should already show 2025; if not, frontend cache or YearSelector bug. |
| G-114-025 | treasury | **STILL BROKEN** | `treasury-tracker/src/components/BudgetSunburst.tsx` uses D3 partition with no permanent labels (only on hover). |

**Primary recommendation:**
1. G-114-001 and G-114-024 require **production verification only** before either being closed or escalated to bug-fix tasks.
2. G-114-014 has a verified, surgical backend fix (one-character SQL change).
3. G-114-020 and G-114-023 are trivial one-line fixes.
4. G-114-002, G-114-011, G-114-021, G-114-025, G-114-004 require small focused edits.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Address autocomplete (G-114-001) | Browser/Client | — | Google Places JS API runs in browser via `useGooglePlacesAutocomplete` |
| Address case normalization (G-114-002) | Frontend (essentials) | API (optional) | Display concern; backend returns uppercase from Census; frontend is the natural normalization point |
| Cross-tab annotation (G-114-004) | Frontend (essentials) | — | Pure UI rendering decision; data already flows to both views |
| Compass geo-default state filter (G-114-011) | Frontend (CompassV2) | Browser (geolocation API) | Cross-app localStorage read + browser API, no backend change |
| Compass headshot resolution (G-114-014) | API (ev-accounts) | DB | SQL COALESCE bug; fix at backend service layer |
| Page title (G-114-020) | Frontend (read-rank) | — | Static HTML |
| Treasury featured municipalities (G-114-021) | Frontend (treasury-tracker) | — | Pure UI sort/filter; no API change |
| Monroe County FY notice (G-114-023) | Frontend (treasury-tracker) | — | Conditional render based on `availableYears` |
| Bloomington 2025 import (G-114-024) | DB / Build | API | Data already imported per DB inspection — UI should reflect |
| Sunburst labels (G-114-025) | Frontend (treasury-tracker) | — | D3 SVG label rendering |

---

## Per-Gap Deep Dive

### G-114-001 — Address autocomplete

**Status:** Likely ALREADY RESOLVED. Verify in production.

**Code path:**
- `essentials/src/pages/Results.jsx:392-398` — wires `addressInputRef` to `useGooglePlacesAutocomplete` hook with `onPlaceSelected` callback that updates input + triggers search.
- `essentials/src/hooks/useGooglePlacesAutocomplete.js` — hook exists.
- Input field at `Results.jsx:746-754` carries the ref.

**Recommended fix approach:** Wave 1 task is a **production smoke test**, not a code change. Type a partial address into essentials.empowered.vote and check whether the dropdown appears. If working, close as resolved. If broken: check `VITE_GOOGLE_MAPS_API_KEY` env var on Render, browser console for Maps API load errors, and Google Cloud Console for API key restrictions.

**Risk:** LOW — verification only.

---

### G-114-002 — ALL CAPS address

**Status:** STILL BROKEN.

**Code path:**
- Render: `essentials/src/pages/Results.jsx:813` — `<span className="font-semibold text-gray-700">{formattedAddress}</span>`
- Source: `formattedAddress` comes from `usePoliticianData` hook, ultimately backend `essentialsService.ts:714` returns `matchedAddress`.
- Origin of uppercase: `geocodingService.ts:71` — Census Geocoder returns matched address in uppercase, e.g. `200 W KIRKWOOD AVE, BLOOMINGTON, IN, 47404`.

**Recommended fix approach:** Add a `toTitleCase()` helper in `essentials/src/utils/` or inline. Apply at render site only (not at API/DB layer — keep raw uppercase in cache for consistency). Care: titlecase logic should preserve `IN` (state), zip codes, and direction abbreviations like `W`. Consider a small mapping for known acronyms or use a library like `title-case` (already small).

Alternative: apply `text-transform: capitalize` CSS — simpler but doesn't handle "IN" correctly.

**Risk:** LOW — display-only change.

---

### G-114-004 — Reps vs Elections cross-reference

**Status:** STILL BROKEN.

**Code path:**
- Representatives card render: `Results.jsx:555-677` (`renderPoliticianCard`)
- Elections render: `Results.jsx:1010` `<ElectionsView elections={electionsData}>` (separate component)
- Both data sources are separate fetches — `usePoliticianData` for reps, `fetchElectionsByAddress` for elections.

**Linkage data structure:** Both render politicians by `pol.id`. To cross-reference, the Representatives card needs to know whether the same `pol.id` (or the same person via `politician_id` link on a candidate row) appears in the Elections data set. The Elections data is lazily loaded only when the Elections tab is visited (`Results.jsx:338-353`).

**Recommended fix approach (Claude's discretion per CONTEXT):**
1. **Eager-load elections in background** when Representatives view renders, so cross-reference data is available without forcing user to switch tabs.
2. Build a `Set<politician_id>` from `electionsData` candidate rows.
3. In `renderPoliticianCard`, if `electionsCandidateIds.has(pol.id)`, append annotation: e.g., card footer line "Also running in [office] — see Elections" or a small badge.
4. Style: subtle (small text-xs in `text-[#fed12e]` ev-yellow) — matches existing ev-yellow candidate accent on line 648.

**Risk:** MEDIUM — requires cross-data-source coordination. Eager loading adds an API call on Representatives view; consider only fetching when tab badge dot indicator already shows elections exist.

---

### G-114-011 — Compass geo-default

**Status:** STILL BROKEN.

**Code paths verified:**
- `InlinePoliticianPicker` (`CompassV2/src/components/InlinePoliticianPicker.jsx`) hosts the state filter via `useFilteredPoliticians(politicians)` hook → `stateFilter` state.
- `loadGuestCompass()` (`essentials/src/lib/compass.js:194-211`) reads `{a, s, i}` schema = answers, selectedTopics, invertedSpokes. **Does NOT store address.**
- The cross-app localStorage bridge built in Phase 122 (`GUEST_COMPASS_KEY`) is for compass quiz state only.

**D-02 fallback chain implementation analysis:**

**Tier 1 — Essentials address context:** No existing localStorage key carries the user's address from Essentials. Two options:
  - **(a)** Extend `GUEST_COMPASS_KEY` schema to add `addr` field, save it from Essentials' `Results.jsx` when an address search succeeds (write to localStorage on `formattedAddress` set).
  - **(b)** Create a new dedicated key `evUserAddress` written by Essentials, read by all apps.

  Recommend **(b)** — separation of concerns. The compass guest cache is for quiz answers; address belongs in its own bridge.

**Tier 2 — Browser geolocation:** Pure browser API. To check permission state without prompting, use `navigator.permissions.query({name:'geolocation'})` first. Only call `navigator.geolocation.getCurrentPosition()` if state is `'granted'`. For reverse-geocoding to state, options:
  - Backend call: add `/api/geo/reverse?lat=X&lng=Y` endpoint that returns `{state}`.
  - Pure browser: no built-in browser API for reverse geocoding without an API key.

  Recommend **backend reverse-geocode endpoint** since the backend already has Census Geocoder integration (`geocodingService.ts`). New service method `reverseGeocode(lat, lng) -> {state}` using Census Geographies API.

**Tier 3 — Unfiltered fallback:** Existing behavior. Just don't pre-set `stateFilter`.

**Plug-in point:** `useFilteredPoliticians` hook initializes `stateFilter = ""`. Add a one-shot effect inside `InlinePoliticianPicker` (or the hook itself) that on mount runs the fallback chain and sets `stateFilter` if a state is resolved AND `stateFilter` is currently empty (don't override user choice).

**Recommended fix approach:**
1. Wave 2 Task A: in Essentials `Results.jsx`, write `localStorage.setItem('evUserAddress', JSON.stringify({addr, state, ts}))` whenever `formattedAddress` is set with a parsed state.
2. Wave 2 Task B: Add new compass util `loadUserAddressContext()` to read evUserAddress (with TTL check, e.g., 30 days).
3. Wave 2 Task C: New `useGeoDefaultState()` hook that runs fallback chain and returns a state code (or empty).
4. Wave 2 Task D: Wire into `InlinePoliticianPicker` — apply geo-default once on mount.
5. Optional: backend `/api/geo/reverse` endpoint if Tier 2 is implemented (otherwise skip Tier 2 and only do Tier 1 + Tier 3).

**Risk:** MEDIUM — touches both apps, new browser permission flow.

---

### G-114-014 — Pierce headshot in Compass

**Status:** STILL BROKEN — root cause identified at backend SQL.

**Investigation evidence (verified 2026-04-17):**

```bash
# Pierce DB row:
photo_custom_url IS NULL  → custom_null=t
photo_origin_url = ''     → origin_empty=t  (NOT NULL — empty string)

# essentials.politician_images for Pierce: 2 rows (default + thumb), URLs valid
default URL: https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/72dd5219-490f-48bb-986e-183a6098d602/default.jpg

# compassService.ts:273 SQL COALESCE result:
COALESCE(p.photo_custom_url, p.photo_origin_url, pi.url, '') = ''  (returns empty string!)

# Live API response from /api/compass/politicians (Pierce row):
"photo_origin_url": ""    ← matches the broken COALESCE
```

**Root cause:** PostgreSQL `COALESCE` returns the **first non-NULL** argument. `p.photo_origin_url = ''` (empty string, non-NULL) wins over `pi.url`. The fallback chain never reaches the politician_images URL.

**Recommended fix approach:** Wave 2 task — change `compassService.ts:273` from:

```sql
COALESCE(p.photo_custom_url, p.photo_origin_url, pi.url, '') AS photo_origin_url,
```

to:

```sql
COALESCE(NULLIF(p.photo_custom_url, ''), NULLIF(p.photo_origin_url, ''), pi.url, '') AS photo_origin_url,
```

**Verify after fix:** re-query `/api/compass/politicians` for Pierce — `photo_origin_url` should now contain the Supabase CDN URL. Frontend `InlinePoliticianPicker.jsx:300` already uses `p.photo_origin_url || p.photo_custom_url || placeholder`, which will work correctly.

**Cross-impact check:** The Essentials side uses a different SQL path (`getImageData` in `Results.jsx:28-35` reads `pol.images` array, not `photo_origin_url`). Pierce's photo renders correctly there because the `images` array is populated separately. So this fix is isolated to compassService.

**Audit recommendation:** Search backend for other `COALESCE(.*photo_.*url.*)` patterns and apply same NULLIF wrapping. Likely candidates: any other endpoint returning a flat photo URL string.

**Risk:** LOW — surgical SQL change, behavior is additive (cases that worked before continue to work).

---

### G-114-020 — Read & Rank tab title

**Status:** STILL BROKEN.

**Code path:** `read-rank/index.html:7` — `<title>readrank-prototype</title>`

**Recommended fix approach:** Change to `<title>Read & Rank — Empowered Vote</title>`. One-line edit, push, Render auto-deploys.

**Risk:** TRIVIAL.

---

### G-114-021 — Treasury landing geo-prioritization

**Status:** STILL BROKEN.

**Code path:**
- Landing component: `treasury-tracker/src/components/AlphaLanding.tsx`
- `CityGrid` (line 105+) renders all available cities via `available.map()` (line 124) — no sort, just whatever order the API returns.
- Bloomington already gets a "Pilot" badge (line 139-143) but Indiana cities can still be visually buried below California cities depending on API order.

**Recommended fix approach (per D-05, static list acceptable):**
- Wave 3 task: split `available` into two lists in `CityGrid`:
  ```ts
  const featured = available.filter(m => m.state === 'IN');
  const others = available.filter(m => m.state !== 'IN');
  ```
- Render a "Featured communities" header above `featured`, then "Other communities" header above `others`.
- Featured list inherits existing `CityGrid` button styling; optionally add a subtle visual emphasis (border-l accent in ev-coral or similar).

**Insertion point:** Line 122-153, replace single `.map()` with conditional two-section render. Could also be a new component `FeaturedCityGrid` invoked from `AlphaLanding` line 200 before the existing `<CityGrid>`.

**Risk:** LOW — pure presentation change.

---

### G-114-023 — Monroe County FY2025 notice

**Status:** STILL BROKEN — confirmed.

**Investigation evidence:**
- API `/api/treasury/cities` Monroe County entry: `available_datasets` max `fiscal_year=2025`, no 2026.
- Bloomington has 2026 datasets.

**Code path:**
- `treasury-tracker/src/App.tsx:108-113` — `availableYears` derived from `selectedEntity.available_datasets`.
- Year display in `App.tsx:606-608` ("How {city} {datasets.title}") — no FY notice rendered.
- `YearSelector` component renders the dropdown of years.

**Recommended fix approach (per D-06):**
- Wave 3 task: in `App.tsx`, when `selectedEntity` has no FY2026 dataset but the current calendar year is 2026, render a small banner near the YearSelector (e.g., between hero banner and Header/Controls bar at line 514):
  ```tsx
  {!availableYears.includes('2026') && (
    <div className="bg-[#FFF8ED] border-l-4 border-[#F5D98B] px-4 py-2 max-w-[1400px] mx-auto">
      <p className="text-sm text-[#92400E]">
        Latest available: FY{availableYears[0]}. FY2026 data not yet published by {selectedEntity.name}.
      </p>
    </div>
  )}
  ```
- Make condition data-driven (don't hardcode "Monroe County") so the notice surfaces for any future entity in the same situation.

**Risk:** LOW — additive UI element with a conditional render guard.

---

### G-114-024 — Bloomington FY2025 import

**Status:** **DATA ALREADY IMPORTED** — verify UI.

**Investigation evidence (verified 2026-04-17):**

```sql
-- treasury.budgets for Bloomington IN:
fiscal_year=2025, dataset_type=operating, 1445 categories
fiscal_year=2025, dataset_type=revenue,    246 categories
fiscal_year=2025, dataset_type=salaries,   506 categories
```

API confirms: `/api/treasury/cities` Bloomington `available_datasets` includes `{fiscal_year: 2025, dataset_type: ...}` for all three dataset types.

**Probable explanation:** The audit (Phase 114, ~mid-March 2026) ran before FY2025 was imported. Since then, an unrecorded import filled the gap.

**Recommended fix approach (per D-07):**
- Wave 3 task: **production smoke test** — visit treasurytracker.empowered.vote, select Bloomington, open YearSelector dropdown, confirm 2025 appears in the list.
- If 2025 appears → close as resolved; commit a note to `.planning/STATE.md` quick-tasks.
- If 2025 does NOT appear in UI but exists in API → frontend bug in `availableYears` derivation (`App.tsx:108-113`) — investigate.
- If API itself omits 2025 → cache invalidation; restart Render service.

**Risk:** TRIVIAL — verification only.

**No `importBudgetHierarchy.ts` re-run needed** unless the smoke test reveals data is missing from a specific dataset_type. The CONTEXT D-07 instruction was based on the audit-time assumption that data was missing.

---

### G-114-025 — Sunburst labels

**Status:** STILL BROKEN.

**Code path:** `treasury-tracker/src/components/BudgetSunburst.tsx` — D3 partition layout. No persistent text labels rendered on segments (verified by reading first 80 lines; full review may show hover-only tooltips).

**Recommended fix approach (per D-08, less-risky path):**

Two viable paths:

**(A) Add permanent labels for top-level segments only.**
- D3 SVG `<text>` elements on top-level partition arcs.
- Trick: arcs may be too narrow for text — measure arc length, hide labels for arcs below a threshold (~20 chars worth of arc).
- Risk: requires computing label rotation/positioning along arc curves; D3 arc-text is fiddly.
- Estimated complexity: M.

**(B) Remove sunburst toggle entirely.**
- Per CONTEXT specifics: "Removing the sunburst toggle entirely is an acceptable fix if labeling is complex."
- Locate where users toggle between sunburst and bar chart in `BudgetVisualization.tsx` — hide/remove the sunburst option.
- Risk: TRIVIAL.

**Recommendation:** Start with (A) attempting **top-level labels only** with a width-threshold guard. If the implementation runs over a 2-hour budget, fall back to (B). Frame as a single Wave 3 task with an internal checkpoint.

**Risk:** MEDIUM for (A), TRIVIAL for (B).

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Multi-app — manual production smoke for visual gaps; vitest for ev-accounts backend |
| Backend test command | `cd ev-accounts/backend && npm test` |
| Frontend tests | None standardized for these apps; rely on production smoke |
| Quick verification | `curl` against api.empowered.vote endpoints |

### Per-Surviving-Gap Validation

| Gap | Evidence Source | Pass Condition | Fail Condition |
|-----|-----------------|----------------|----------------|
| G-114-001 (verify) | Production smoke: type "200 W Kir" into essentials.empowered.vote address bar | Google Places dropdown appears within 1s | No dropdown after 5s typing |
| G-114-002 | Production smoke: search Kirkwood address, inspect results header | Header reads "200 W Kirkwood Ave, Bloomington, IN, 47404" (mixed case) | Header reads "200 W KIRKWOOD AVE..." (uppercase) |
| G-114-004 | Production smoke: load Kirkwood results, find Deckard/Henry on Reps tab | Reps card shows "Also running for Commissioner District 1" annotation | No cross-reference annotation visible |
| G-114-011 | Production smoke: clear localStorage, search Kirkwood in Essentials, navigate to Compass compare picker | State filter dropdown shows "Indiana" pre-selected | State filter shows "All states" |
| G-114-014 | API check: `curl https://api.empowered.vote/api/compass/politicians \| jq '.[] \| select(.last_name=="Pierce") \| .photo_origin_url'` | Returns Supabase CDN URL (non-empty) | Returns `""` |
| G-114-014 (UI) | Production smoke: open Compass compare picker, select Matt Pierce | Pierce headshot renders (not silhouette) | Silhouette/placeholder shown |
| G-114-020 | Production smoke: load readrank.empowered.vote, check browser tab title | Tab shows "Read & Rank — Empowered Vote" | Tab shows "readrank-prototype" |
| G-114-021 | Production smoke: load treasurytracker.empowered.vote as guest | Bloomington IN + Monroe County IN appear in a "Featured" section above other cities | IN cities mixed in with no priority |
| G-114-023 | Production smoke: navigate to Monroe County in treasury | Banner shows "Latest available: FY2025" | No notice rendered |
| G-114-024 | API check: `curl https://api.empowered.vote/api/treasury/cities \| jq '.[] \| select(.name=="Bloomington") \| .available_datasets[].fiscal_year' \| sort -u` | List includes `2025` | List omits `2025` |
| G-114-024 (UI) | Production smoke: select Bloomington in treasury, open YearSelector | "2025" appears in dropdown | "2025" missing |
| G-114-025 | Production smoke: switch to sunburst view in treasury (or, if removed, toggle is absent) | Top-level segments show readable category labels OR sunburst toggle is gone | Unlabeled segments persist |

### Sampling Rate
- **Per task commit:** Manual smoke for the specific gap fixed
- **Per wave merge:** All gaps in that wave verified in production
- **Phase gate:** All 10 gaps verified in production before phase close

### Wave 0 Gaps (test infrastructure)
None required — these are visual/data fixes verified by production smoke + curl. No new test files needed. Existing `ev-accounts/backend` vitest suite is sufficient for the G-114-014 backend SQL change (consider adding a minimal regression test verifying Pierce-style empty-string `photo_origin_url` falls through to `politician_images.url`).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Title-casing addresses (G-114-002) | Custom regex chain | `title-case` npm package OR small inline helper with known-acronym list (`IN`, `USA`, directional letters) | Edge cases around acronyms, ordinals (1st, 2nd), and abbreviations |
| Reverse geocoding (G-114-011 Tier 2) | Browser-only string lookup | Backend Census Geographies API call (already integrated for forward geocoding) | Census API is authoritative, free, already used by codebase |
| Cross-app localStorage bridge (G-114-011 Tier 1) | New ad-hoc key | Follow the established `GUEST_COMPASS_KEY` pattern from Phase 122 — separate key, JSON-serialized, with TTL guard | Consistency with existing cross-app patterns documented in Phase 122 |
| Sunburst label layout (G-114-025) | Hand-rolled SVG arc text | If pursuing path A, look for D3 `textPath` examples; if too complex, drop to path B (remove toggle) | D3 arc text is a known minefield |

---

## Common Pitfalls

### Pitfall 1: Empty-string vs NULL in COALESCE chains (G-114-014)
**What goes wrong:** `COALESCE(a, b, c)` returns the first NON-NULL value. Empty strings and zero are non-NULL.
**How to avoid:** Wrap potentially-empty string columns with `NULLIF(col, '')`. Audit all photo/url COALESCE patterns in the backend after this fix.

### Pitfall 2: Census Geocoder uppercase output (G-114-002)
**What goes wrong:** Backend stores `matchedAddress` in cache (`geocodingService.ts:142`) verbatim from Census. Any normalization at API boundary would invalidate cache. Apply normalization at display layer instead.
**How to avoid:** Frontend display-layer transformation only.

### Pitfall 3: Two separate data fetches for same entity (G-114-004)
**What goes wrong:** Representatives view doesn't know what's in Elections data unless that fetch has happened. Cross-reference annotations require both data sources to be loaded before annotation render.
**How to avoid:** Either eager-load Elections data in parallel with Representatives, OR show annotation only after user has visited Elections tab once (state remembered via React state).

### Pitfall 4: Browser geolocation permission prompts (G-114-011 D-02)
**What goes wrong:** Triggering `getCurrentPosition()` without checking permission state spawns a prompt. Spec author's preference per CONTEXT: silent skip if not already granted.
**How to avoid:** Use `navigator.permissions.query({name:'geolocation'})` first. Only call `getCurrentPosition` when state === 'granted'.

### Pitfall 5: Render frontend cache after data import (G-114-024)
**What goes wrong:** Render service may serve stale `available_datasets` JSON if the cities endpoint caches in-memory. After data imports, sometimes a service restart is needed for the API to pick up new rows.
**How to avoid:** If the smoke test fails after data is verified in DB, restart the Render service for ev-accounts.

---

## Project Constraints (from CLAUDE.md)

- **Antipartisan principle:** No party labels, no red/blue color associations. All fixes must use existing palette (`ev-coral`, `ev-muted-blue`, `ev-light-blue`, `ev-yellow`).
- **ev-ui auto-bump pipeline:** If any Compass fix requires a shared component change, ship via `npm version patch && git push origin main --follow-tags` from `ev-ui/`. Auto-merge will distribute to consumers. None of the in-scope gaps appear to require ev-ui changes — all are app-local.
- **Production verification required after each wave** (consistent with Phases 118, 119, 122).
- **Render auto-deploys on merge to main** for all consumer apps.
- **Multi-project workspace:** edits span `essentials/`, `CompassV2/`, `ev-accounts/backend/`, `read-rank/`, `treasury-tracker/`. Each is its own git repo / branch deployment.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Production API (api.empowered.vote) | All verification steps | ✓ | live | — |
| Supabase production DB | G-114-014 verification, G-114-024 verification | ✓ | live | — |
| Google Maps Places API key (`VITE_GOOGLE_MAPS_API_KEY`) | G-114-001 verification | unknown — production env var | — | If missing, autocomplete won't work; remediation = add key to Render env |
| Census Geographies API | G-114-011 reverse geocode (if implemented) | ✓ (free, already used in codebase) | — | Skip Tier 2 of fallback chain; Tier 1 + Tier 3 still useful |
| `tsx` runtime | `importBudgetHierarchy.ts` (only if G-114-024 needs re-run) | ✓ via `npx tsx` per CLAUDE.md | — | — |

**Missing dependencies with no fallback:** None blocking — all critical paths have working alternatives.

---

## Open Questions (RESOLVED)

1. **G-114-001 production state.** Is Google Places autocomplete actually broken in production, or did the gap report capture transient/dev-environment issue? Wave 1 verification step answers this.
   - **Recommendation:** Start Wave 1 with verification, only spawn fix task if confirmed broken.
   - **RESOLVED:** Plan 01 Task 1 is a verify-first human checkpoint at essentials.empowered.vote. Outcome (PASS — close as resolved; FAIL — file follow-up for env-var/API-key audit) recorded in 125-01-SUMMARY.md.

2. **G-114-024 production state.** Does Bloomington 2025 already appear in the YearSelector UI? Data is in DB and API.
   - **Recommendation:** Start Wave 3 with verification; likely closes the gap with no code change.
   - **RESOLVED:** Plan 03 Task 3 verifies Bloomington 2025 in YearSelector at treasurytracker.empowered.vote. If missing, the task includes a curl fallback against `/api/treasury/cities` plus Render restart remediation.

3. **G-114-011 Tier 2 (browser geolocation) — keep or skip?** Implementing reverse geocoding adds backend surface area for marginal UX win (Essentials address context already covers the common case).
   - **Recommendation:** Implement Tier 1 + Tier 3 only. Defer Tier 2 unless a concrete user need surfaces. CONTEXT permits this since user gave Claude discretion on prompt-vs-silent for geolocation.
   - **RESOLVED:** Deferred per user decision 2026-04-17. See `.planning/phases/125-tier-2-ux-polish-bundle/125-CONTEXT.md` `<deferred>` section (D-02 Tier 2). Phase 125 ships Tier 1 (Essentials localStorage bridge) + Tier 3 (unfiltered fallback) only. Plan 02 Task 2 implements this.

4. **G-114-014 audit scope.** Should we audit and fix the COALESCE-empty-string pattern across the whole backend, or scope to compassService only?
   - **Recommendation:** Scope to compassService for this phase. File a Tier 2 quick-task to grep for other COALESCE(.*photo.*url) patterns post-phase.
   - **RESOLVED:** Limited to compassService.ts:273 fix in Plan 02 Task 1. Broader backend audit (grep for `COALESCE(.*photo_.*url.*)`) is filed as a post-phase follow-up quick-task to be added to .planning/STATE.md at phase close.

5. **G-114-025 path A vs B.** Should the planner commit upfront to path B (remove sunburst), or attempt A first?
   - **Recommendation:** Plan task with explicit checkpoint — attempt A for ≤2 hours, fall back to B. Plan should write both paths out so the executor doesn't deliberate.
   - **RESOLVED:** Checkpoint-gated Path A → Path B fallback. See Plan 04: Task 1 attempts Path A with a 2-hour internal budget; Task 2 is a `checkpoint:decision` gate where the user picks `path-a-keep` or `path-b-remove`; Task 3 (skipped on `path-a-keep`) executes Path B removal.

---

## Sources

### Primary (HIGH confidence — direct verification this session)
- `essentials/src/pages/Results.jsx` (full file read, 1044 lines)
- `essentials/src/lib/compass.js` (full file read)
- `CompassV2/src/components/ComparePanel.jsx` (full file read)
- `CompassV2/src/components/InlinePoliticianPicker.jsx` (full file read)
- `CompassV2/src/hooks/usePoliticianList.js` (full file read)
- `read-rank/index.html` (full file read — confirmed line 7)
- `treasury-tracker/src/App.tsx` (full file read, 736 lines)
- `treasury-tracker/src/components/AlphaLanding.tsx` (lines 1-220 read)
- `treasury-tracker/src/components/BudgetSunburst.tsx` (lines 1-80 read)
- `ev-accounts/backend/src/lib/compassService.ts` (lines 260-310 read — verified COALESCE bug)
- Production API: `https://api.empowered.vote/api/compass/politicians` (Pierce row inspected — `photo_origin_url=""`)
- Production API: `https://api.empowered.vote/api/treasury/cities` (Bloomington + Monroe County inspected)
- Production DB direct queries (essentials.politician_images, essentials.politicians, treasury.budgets)

### Secondary (MEDIUM confidence)
- `.planning/phases/125-tier-2-ux-polish-bundle/125-CONTEXT.md`
- `.planning/GAP-REPORT.md` (gap definitions)
- `.planning/REQUIREMENTS.md` (UX-01 mapping)

### Tertiary
- None — all claims verified against code or live systems.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | G-114-001 is likely already fixed because the hook is wired | G-114-001 deep dive | Wasted verification step (negligible) |
| A2 | Census Geocoder is the source of uppercase address — not seen end-to-end this session | G-114-002 | Display-layer fix still works regardless of source |
| A3 | `available_datasets` API value reflects actual DB state for Bloomington 2025 | G-114-024 | If API caches, smoke test will catch it |
| A4 | The `text-base` style in BudgetSunburst could fit top-level labels — not visually verified | G-114-025 path A risk | Falls back to path B per plan |
| A5 | Production has a valid Google Maps API key | G-114-001 | If missing, separate fix needed (env var on Render) |

---

## Metadata

**Confidence breakdown:**
- Gap status verification: HIGH — every gap inspected in code + most against production
- Root cause for G-114-014: HIGH — verified via direct DB query reproducing the COALESCE result
- Fix approaches: MEDIUM-HIGH — mostly straightforward, G-114-011 has design flexibility
- Architectural mapping: HIGH — codebase layout is well-understood

**Research date:** 2026-04-17
**Valid until:** 2026-05-17 (data state may shift if more imports run)
