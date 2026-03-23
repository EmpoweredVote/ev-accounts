---
phase: 95-entity-switcher
verified: 2026-03-23T00:00:00Z
status: passed
score: 4/4 must-haves verified
re_verification: false
---

# Phase 95: Entity Switcher Verification Report

**Phase Goal:** Users can navigate between all available jurisdictions in a single Treasury Tracker session — Bloomington, Ellettsville, Monroe County, LA County, and LA City — without reloading the page
**Verified:** 2026-03-23
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A dropdown shows all available entities grouped by type (city vs. county); selecting one updates the entire page to show that entity's data | VERIFIED | EntitySwitcher.tsx groups by `entity_type` into Cities/Counties/Townships groups; `onEntityChange` triggers `handleEntityChange` in App.tsx which calls `setSelectedEntity`, `setSelectedYear`, `setActiveDataset`, and `syncURL` — all data-loading `useEffect` hooks depend on `selectedEntity` |
| 2 | The hero card, breadcrumbs, and dataset tabs reflect the selected entity — no hardcoded Bloomington content remains | VERIFIED | App.tsx line 387: `{selectedEntity.name} Finances`; breadcrumb line 240: `selectedEntity?.name ?? 'City'` (fallback unreachable after mount guard); `availableDatasets={availableDatasetTypes}` passed to DatasetTabs; hero background uses `selectedEntity.hero_image_url` with a fallback image |
| 3 | Switching from a city entity to a county entity shows the county label correctly (not "Monroe County, City") | VERIFIED | EntitySwitcher renders `{entity.name}, {entity.state}` (e.g., "Monroe County, IN") — the `entity_type` field is used only for grouping headers (Cities/Counties), never appended to the display name |
| 4 | Switching entities triggers a fresh data load with the correct cache key — no stale cross-entity data can appear from a prior selection | VERIFIED | `dataLoader.ts` cache key is `${municipalityName}-${municipalityState}-${year}-${dataset}` (line 25); `handleEntityChange` computes `effectiveYear` before calling `setSelectedEntity` to prevent race-condition stale reads (Pitfall 1 guard); data-load `useEffect` depends on `[activeDataset, selectedYear, selectedEntity]` |

**Score:** 4/4 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `EV-Backend/internal/treasury/models.go` | Municipality with HeroImageURL field | VERIFIED | Line 17: `HeroImageURL *string` (nullable pointer, `json:"hero_image_url,omitempty"`) |
| `EV-Backend/internal/treasury/handlers.go` | ListMunicipalities with available_datasets | VERIFIED | `DatasetSummary` struct (lines 17-20), `MunicipalityResponse` struct with `AvailableDatasets []DatasetSummary` (line 30), two-query aggregation in `ListMunicipalities` (lines 34-81) |
| `treasury-tracker/src/types/budget.ts` | Municipality interface | VERIFIED | Lines 77-88: `export interface Municipality` with `entity_type`, `hero_image_url?`, `available_datasets` array |
| `treasury-tracker/src/data/dataLoader.ts` | Updated cache key with state; listMunicipalities returns Municipality[] | VERIFIED | Line 22: `municipalityState: string = 'IN'`; line 25: state-aware cache key; line 84: `Promise<Municipality[]>` return type |
| `treasury-tracker/src/components/EntitySwitcher.tsx` | Entity dropdown grouped by type | VERIFIED | Full implementation with `interface EntitySwitcherProps`, `aria-label="Select jurisdiction"`, `role="listbox"`, `entity-group-label`, `role="option"`, click-outside + Escape dismiss |
| `treasury-tracker/src/components/EntitySwitcher.css` | EntitySwitcher styling per UI-SPEC | VERIFIED | `.entity-switcher-button` with `min-height: 44px`; `.entity-option.selected` with left border; `.entity-group-label` with uppercase styling |
| `treasury-tracker/src/App.tsx` | Entity state management, URL sync, dynamic hero | VERIFIED | `selectedEntity`, `municipalities` state; `toSlug`, `syncURL`, `handleEntityChange`; `pushState`; `{selectedEntity.name} Finances`; `selectedEntity.hero_image_url` conditional; `selectedEntity.population > 0` guard |
| `treasury-tracker/src/App.css` | Spinner overlay CSS | VERIFIED | `.content-loading-overlay`, `.spinner`, `@keyframes spin` all present (lines 1446, 1456, 1268/1465) |
| `treasury-tracker/src/components/datasets/DatasetTabs.tsx` | Disabled tab state for unavailable datasets | VERIFIED | `availableDatasets?: string[]` prop; `available` variable with fallback; `pointerEvents: 'none'`, `aria-disabled` on both desktop tabs and mobile dropdown items |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `App.tsx` | `EntitySwitcher.tsx` | import and props | VERIFIED | Line 5: `import EntitySwitcher`; line 342-346: `<EntitySwitcher municipalities={municipalities} selectedEntity={selectedEntity} onEntityChange={handleEntityChange} />` |
| `App.tsx` | `dataLoader.ts` `loadBudgetData` | `selectedEntity` in useEffects | VERIFIED | Lines 142, 145, 168: `loadBudgetData(..., selectedEntity.name, selectedEntity.state, ...)` — state included in every call |
| `App.tsx` | `window.history.pushState` | `syncURL` function | VERIFIED | Line 33: `window.history.pushState({}, '', ...)` inside `syncURL`; called in `handleEntityChange` (line 195) and URL-sync `useEffect` (line 201) |
| `dataLoader.ts` | `/treasury/municipalities` | fetch call in `listMunicipalities` | VERIFIED | Line 85: `fetch(\`${API_BASE}/treasury/municipalities\`)` |
| `budget.ts` Municipality interface | `handlers.go` MunicipalityResponse | API response shape | VERIFIED | Both have `id`, `name`, `state`, `entity_type`, `population`, `hero_image_url`, `available_datasets` with matching `fiscal_year`/`dataset_type` fields |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| `EntitySwitcher.tsx` | `municipalities` prop | `listMunicipalities()` in App.tsx mount effect → `GET /treasury/municipalities` → `db.DB.Find(&municipalities)` + `db.DB.Model(&Budget{}).Select(...)` | Yes — two live DB queries, no static return | FLOWING |
| `App.tsx` hero section | `selectedEntity` | Resolved from `municipalities` list after API load; defaults to Bloomington or list[0] | Yes — derived from live API data | FLOWING |
| `DatasetTabs.tsx` | `availableDatasetTypes` | `useMemo` over `selectedEntity.available_datasets` filtered by `selectedYear` | Yes — derived from live API data | FLOWING |
| `App.tsx` budget section | `budgetData` | `loadBudgetData(...)` → `GET /treasury/budgets?city=...&year=...&dataset=...` → DB query | Yes — live DB query returning real budget data | FLOWING |

---

### Behavioral Spot-Checks

Step 7b: SKIPPED — verification requires a running backend and browser (API calls depend on Supabase connection; cannot test without live server). Human verification checkpoint (Task 3 of Plan 02) was completed and approved per 95-02-SUMMARY.md.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| UI-01 | 95-02-PLAN.md | User can switch between entities (cities/counties) via dropdown | SATISFIED | EntitySwitcher.tsx fully implemented; `handleEntityChange` in App.tsx updates all state on selection |
| UI-02 | 95-02-PLAN.md | Hero card, breadcrumbs, and dataset tabs update dynamically per selected entity | SATISFIED | `{selectedEntity.name} Finances`; `selectedEntity?.name ?? 'City'` in breadcrumbs; `availableDatasets={availableDatasetTypes}` in DatasetTabs |
| UI-03 | 95-02-PLAN.md | Entity switcher groups entities by type (city vs county) | SATISFIED | EntitySwitcher.tsx groups by `entity_type` into Cities/Counties/Townships sections with `entity-group-label` headers |
| UI-04 | 95-01-PLAN.md | dataLoader.ts cache key includes entity state to prevent cross-entity collisions | SATISFIED | Cache key: `` `${municipalityName}-${municipalityState}-${year}-${dataset}` `` (dataLoader.ts line 25) |

**All four Phase 95 requirements satisfied. No orphaned requirements.**

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `treasury-tracker/src/App.tsx` | 240 | `selectedEntity?.name ?? 'City'` fallback | Info | The `'City'` string is a TypeScript null-safety fallback only; unreachable in practice because the `if (!selectedEntity)` guard at line 269 returns a spinner before the breadcrumb code executes. Not a hardcoded stub. |
| `treasury-tracker/src/components/PerDollarBreakdown.tsx` | 165 | "total city budget" in tooltip text | Info | Refers to "city budget" in a generic financial explanation tooltip in a secondary component not in Phase 95 scope. No impact on entity-switching goal. |
| `treasury-tracker/src/App.tsx` | 378 | Hardcoded fallback image URL (Bloomington courthouse) | Info | Intentional documented behavior — `hero_image_url` column not yet populated for entities. SUMMARY.md explicitly documents this as known, with fallback working correctly. Not a stub. |

No blockers found.

---

### Human Verification Required

All automated checks passed. The following items were verified by the user during Plan 02, Task 3 (blocking human-verify checkpoint per SUMMARY.md):

**1. Entity switching end-to-end**

**Test:** Open treasury-tracker, click entity dropdown, select Monroe County, select LA County
**Expected:** Page data updates without page reload; hero title, year selector, dataset tabs all reflect the new entity
**Why human:** Requires a running backend with live Supabase data and a browser

**2. URL deep linking**

**Test:** Navigate to `?entity=monroe-county-in&year=2024&dataset=operating`
**Expected:** Monroe County data loads directly; invalid entity param falls back to Bloomington
**Why human:** Requires browser URL manipulation and API connectivity

**3. Spinner overlay behavior**

**Test:** Switch entities and observe the transition
**Expected:** Spinner overlay appears over content while header (including EntitySwitcher) stays interactive
**Why human:** Requires observing CSS animation behavior in a real browser

**4. Dataset tab disabled state**

**Test:** Switch to an entity that lacks revenue or salary data; observe tab states
**Expected:** Tabs for missing dataset types appear at 40% opacity and are non-clickable
**Why human:** Requires entities with partial dataset coverage in the database

Per 95-02-SUMMARY.md: "Task 3: Visual verification — approved by user"

---

### Gaps Summary

No gaps. All four success criteria are verified by code inspection:

- **SC1 (grouped dropdown + page update):** EntitySwitcher groups by `entity_type`; `handleEntityChange` triggers full state update
- **SC2 (no hardcoded Bloomington):** Hero title, breadcrumbs, dataset tabs all driven by `selectedEntity` state
- **SC3 (county label correct):** Display format is always `{name}, {state}` — `entity_type` only used for group headers, never appended to display name
- **SC4 (fresh data load with correct cache key):** Cache key includes `municipalityState`; Pitfall 1 guard ensures `effectiveYear` computed before `setSelectedEntity`

NavigationTabs.tsx deleted as required. TypeScript compilation exits 0. Go backend builds without errors.

---

_Verified: 2026-03-23_
_Verifier: Claude (gsd-verifier)_
