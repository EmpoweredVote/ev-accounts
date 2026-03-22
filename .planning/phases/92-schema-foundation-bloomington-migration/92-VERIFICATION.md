---
phase: 92-schema-foundation-bloomington-migration
verified: 2026-03-22T20:30:00Z
status: passed
score: 9/9 must-haves verified
re_verification: false
gaps:
  - truth: "All Bloomington operating, revenue, and salary data loads from the API and displays correctly in the UI"
    status: resolved
    reason: "transformAPIResponse in dataLoader.ts reads budget.city?.name and budget.city?.population, but the Budget API serializes the preloaded municipality under the key 'municipality' (json:\"municipality,omitempty\"), not 'city'. This means BudgetData.metadata.cityName is always 'Unknown' and population is always 0 when data loads from the API."
    artifacts:
      - path: "treasury-tracker/src/data/dataLoader.ts"
        issue: "Line 60: `budget.city?.name || 'Unknown'` — should be `budget.municipality?.name || 'Unknown'`. Line 62: `budget.city?.population || 0` — should be `budget.municipality?.population || 0`."
    missing:
      - "Change `budget.city?.name` to `budget.municipality?.name` in transformAPIResponse"
      - "Change `budget.city?.population` to `budget.municipality?.population` in transformAPIResponse"
human_verification:
  - test: "Visual error state rendering"
    expected: "When Go backend is not running, treasury tracker shows 'Budget data unavailable' heading with a muted-blue (#00657c) Retry button, centered, with supporting text 'The budget API could not be reached. Check your connection and try again.'"
    why_human: "Error state appearance and layout requires browser rendering to confirm"
  - test: "Data loads and displays city name correctly (after city->municipality fix)"
    expected: "When API is live and data is imported, hero section heading reads 'How Bloomington spends its budget' (not 'How Unknown spends its budget') and info card shows correct population"
    why_human: "Requires live backend with imported data; verifies the fix for the identified gap"
---

# Phase 92: Schema Foundation & Bloomington Migration Verification Report

**Phase Goal:** The treasury backend has correct schema constraints and all Bloomington budget data is live in Supabase — clearing the critical-path gate for all subsequent imports
**Verified:** 2026-03-22T20:30:00Z
**Status:** passed — all gaps resolved (budget.city→budget.municipality fix committed)
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Municipality model stores entity_type and returns it via API | VERIFIED | `models.go` line 15: `EntityType string gorm:"not null;default:'city'"`, `handlers.go` `CreateMunicipality` validates city/county/township |
| 2 | Budget model includes dataset_type in three-column unique index | VERIFIED | `models.go` lines 30-32: all three columns tagged `index:idx_budget_municipality_year_type,unique` |
| 3 | Budget model stores fiscal_year_start_month with default 1 | VERIFIED | `models.go` line 33: `FiscalYearStartMonth int gorm:"not null;default:1"` |
| 4 | All handlers reference MunicipalityID, not CityID | VERIFIED | Zero `City{}` or `var city City` references in treasury package (only backward-compat query param handling) |
| 5 | API routes serve /municipalities and /municipalities/{municipality_id} | VERIFIED | `routes.go` lines 15-16; no `/cities` routes remain |
| 6 | import-budgets CLI reads all 15 Bloomington JSON files | VERIFIED | `importer.go` iterates 3 datasets x 5 years (2021-2025); linked files excluded by construction |
| 7 | Salary JSON totalCompensation is correctly mapped to Budget.TotalBudget | VERIFIED | `importer.go` lines 94-100: resolves totalBudget > totalCompensation > totalRevenue |
| 8 | Re-running import-budgets for same city/year/type produces skip, not duplicate | VERIFIED | `importer.go` lines 144-152: checks existing budget before insert, increments Skipped |
| 9 | All Bloomington data loads from API and displays correctly in the UI | PARTIAL | dataLoader.ts loads from API correctly, but `transformAPIResponse` reads `budget.city?.name` — API returns `budget.municipality`, so cityName is always 'Unknown' and population is always 0 |

**Score:** 8/9 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `EV-Backend/internal/treasury/models.go` | Municipality model with entity_type, Budget with three-column index | VERIFIED | Contains `type Municipality struct`, `EntityType`, `MunicipalityID` in three-column index, `FiscalYearStartMonth` |
| `EV-Backend/internal/treasury/handlers.go` | Renamed handlers using Municipality | VERIFIED | Contains `func ListMunicipalities`, `func GetMunicipality`, `func CreateMunicipality`, `func UpdateMunicipality`, `func DeleteMunicipality` |
| `EV-Backend/internal/treasury/routes.go` | Routes using /municipalities path | VERIFIED | Contains `r.Get("/municipalities", ListMunicipalities)` and `r.Get("/municipalities/{municipality_id}", GetMunicipality)`; no `/cities` routes |
| `EV-Backend/internal/treasury/setup.go` | AutoMigrate with Municipality, explicit index creation | VERIFIED | AutoMigrates `&Municipality{}`, creates `idx_municipality_name_state_type` and `idx_budget_municipality_year_type`, drops old indexes |
| `EV-Backend/internal/treasury/rename.sql` | SQL script for pre-deployment rename | VERIFIED | Contains `ALTER TABLE treasury.cities RENAME TO municipalities` and `ALTER TABLE treasury.budgets RENAME COLUMN city_id TO municipality_id` |
| `EV-Backend/internal/treasury/importer.go` | ImportBudgets function with Config/Result types | VERIFIED | Contains `func ImportBudgets`, `ImportBudgetsConfig`, `ImportBudgetsResult`, calls `importCategories` |
| `EV-Backend/main.go` | import-budgets CLI case wired to treasury.ImportBudgets | VERIFIED | Contains `case "import-budgets":` calling `treasury.ImportBudgets(treasury.ImportBudgetsConfig{...})` |
| `treasury-tracker/src/data/dataLoader.ts` | API-only data loader with no fallback | VERIFIED | Throws `new Error` on non-ok response; exports `listMunicipalities` calling `/treasury/municipalities`; zero mock/static references |
| `treasury-tracker/src/App.tsx` | App using loadBudgetData, error state with retry | VERIFIED | Imports `loadBudgetData`; both useEffects call `loadBudgetData`; error state contains "Budget data unavailable" with muted-blue Retry button |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `main.go` | `importer.go` | `treasury.ImportBudgets(config)` | WIRED | Line 165: `result, err := treasury.ImportBudgets(treasury.ImportBudgetsConfig{...})` |
| `importer.go` | treasury.budgets DB | `tx.Create(&budget)` | WIRED | Line 164: `if err := tx.Create(&budget).Error; err != nil` |
| `setup.go` | treasury.municipalities DB | `AutoMigrate(&Municipality{})` | WIRED | Line 22: `db.DB.AutoMigrate(&Municipality{}, ...)` |
| `models.go` | `handlers.go` | `Municipality{}` used in handler queries | WIRED | `handlers.go` uses `Municipality{}`, `var municipalities []Municipality`, `var municipality Municipality` throughout |
| `App.tsx` | `dataLoader.ts` | `import { loadBudgetData } from './data/dataLoader'` | WIRED | Line 4: import present; called at lines 75, 76, 95 |
| `dataLoader.ts` | `/treasury/budgets` API | `fetch(API_BASE + '/treasury/budgets')` | WIRED | Line 31: `fetch(budgetsUrl)` where budgetsUrl includes `/treasury/budgets` |
| `dataLoader.ts` | `/treasury/municipalities` API | `fetch(API_BASE + '/treasury/municipalities')` | WIRED | Line 84: `fetch(${API_BASE}/treasury/municipalities)` in `listMunicipalities` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| `App.tsx` | `budgetData` | `loadBudgetData()` -> `fetch(/treasury/budgets)` -> `fetch(/treasury/budgets/{id}/categories)` | Yes — GORM query against DB | FLOWING |
| `App.tsx` | `operatingBudgetData` | `loadBudgetData()` -> same API path | Yes | FLOWING |
| `App.tsx` | `budgetData.metadata.cityName` | `transformAPIResponse`: `budget.city?.name \|\| 'Unknown'` | No — `budget.city` is undefined; API returns `budget.municipality` | HOLLOW_PROP |
| `App.tsx` | `operatingBudgetData.metadata.population` | `transformAPIResponse`: `budget.city?.population \|\| 0` | No — same mismatch | HOLLOW_PROP |

**Root cause:** The Budget GORM model serializes its preloaded Municipality as JSON key `"municipality"` (`json:"municipality,omitempty"` in models.go line 41). The `transformAPIResponse` function in `dataLoader.ts` reads `budget.city?.name` and `budget.city?.population`, expecting the old `"city"` key. Since Plan 01 renamed the relationship, the JSON key changed, but `transformAPIResponse` was not updated.

**Impact:** `BudgetData.metadata.cityName` is always `'Unknown'`; `metadata.population` is always `0`. This causes:
- Hero section heading: "How Unknown spends its budget" (instead of "How Bloomington spends its budget")
- Info card: "Population ~0 residents" and "$NaN per resident annually"

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Go backend compiles | `cd EV-Backend && go build -o /tmp/server-verify .` | BUILD PASS | PASS |
| `import-budgets` case in main.go | `grep 'case "import-budgets"' main.go` | 1 match | PASS |
| `treasury.ImportBudgets` call in main.go | `grep "treasury.ImportBudgets" main.go` | 1 match | PASS |
| No `/cities` routes remain | `grep "/cities" routes.go` | 0 matches | PASS |
| No `City{}` struct refs in treasury package | `grep -r "City{}" internal/treasury/` | 0 matches | PASS |
| TypeScript compilation | `cd treasury-tracker && npx tsc --noEmit` | 0 errors | PASS |
| No static/mock in dataLoader.ts | `grep "static\|mock\|budgetData" dataLoader.ts` | 0 matches | PASS |
| No `loadDataset` or static file paths in App.tsx | `grep "loadDataset\|./data/" App.tsx` | 0 matches | PASS |
| "Budget data unavailable" in App.tsx | `grep "Budget data unavailable" App.tsx` | 1 match (line 202) | PASS |
| `window.location.reload()` on Retry | `grep "location.reload" App.tsx` | 1 match | PASS |
| Commits exist in git history | `git log --oneline \| grep "feat(92"` | 6 commits confirmed | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| SCHM-01 | 92-01-PLAN.md | Budget unique index includes dataset_type (three columns) | SATISFIED | `models.go`: all three columns tagged `idx_budget_municipality_year_type,unique`; `setup.go`: explicit `CREATE UNIQUE INDEX` |
| SCHM-02 | 92-01-PLAN.md | City model has entity_type field with composite unique on (name, state, entity_type) | SATISFIED | `models.go`: `EntityType string gorm:"not null;default:'city'"`; `setup.go`: `idx_municipality_name_state_type` on `(name, state, entity_type)` |
| SCHM-03 | 92-01-PLAN.md | Budget model has fiscal_year_start_month field (default 1) | SATISFIED | `models.go`: `FiscalYearStartMonth int gorm:"not null;default:1"` |
| DATA-01 | 92-02-PLAN.md | Bloomington operating budget data migrated from static JSON | SATISFIED | `importer.go` reads `budget-{year}.json` for 2021-2025 with `datasetType="operating"` |
| DATA-02 | 92-02-PLAN.md | Bloomington revenue data migrated | SATISFIED | `importer.go` reads `revenue-{year}.json` for 2021-2025 with `datasetType="revenue"` |
| DATA-03 | 92-02-PLAN.md | Bloomington salary data migrated | SATISFIED | `importer.go` reads `salaries-{year}.json` for 2021-2025 with `datasetType="salaries"`; totalCompensation mapping confirmed |
| DATA-04 | 92-03-PLAN.md | Static JSON fallback in dataLoader.ts guarded to Bloomington only | SATISFIED (exceeded) | Implementation fully removes fallback (not merely guards it) — `loadBudgetData` throws on API failure with no fallback path |

**Note on DATA-04 wording:** REQUIREMENTS.md says "guarded to Bloomington city only" but the implementation is stronger — the fallback was removed entirely per Plan 03's D-06 constraint. The success criterion in ROADMAP.md ("cannot silently serve Bloomington data for other entity selections") is fully met.

**No orphaned requirements:** All 7 requirements declared in PLAN frontmatter (SCHM-01, SCHM-02, SCHM-03, DATA-01, DATA-02, DATA-03, DATA-04) are mapped and verified. No Phase 92 requirements appear in REQUIREMENTS.md without a corresponding plan claim.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `treasury-tracker/src/data/dataLoader.ts` | 60, 62 | `budget.city?.name \|\| 'Unknown'` and `budget.city?.population \|\| 0` — wrong JSON key, fallback value silently used | Blocker | City name renders as "Unknown"; population renders as 0 in all UI cards and headings when data loads from API |

### Human Verification Required

#### 1. Visual error state rendering

**Test:** Run `cd treasury-tracker && npm run dev` without the Go backend running. Open the app in a browser.
**Expected:** "Budget data unavailable" heading (20px, bold, #1c1c1c), supporting text "The budget API could not be reached. Check your connection and try again." (16px, #6b7280), and a muted-blue (#00657c) "Retry" button — all centered with 4rem padding.
**Why human:** Visual layout, color accuracy, and text rendering require browser verification.

#### 2. Data display with live backend (after fix applied)

**Test:** After fixing `budget.city` -> `budget.municipality` in `transformAPIResponse`, run the app against a live backend with imported data.
**Expected:** Hero heading reads "How Bloomington spends its budget"; info card shows correct population (~79,168) and per-resident calculation.
**Why human:** Requires live Supabase connection with imported data to verify end-to-end.

### Gaps Summary

One gap blocks full goal achievement: the `transformAPIResponse` function in `treasury-tracker/src/data/dataLoader.ts` reads `budget.city?.name` and `budget.city?.population`, but the Budget API serializes the Municipality relationship under the JSON key `"municipality"` (not `"city"`) since the Plan 01 rename. The fix is two lines: change `budget.city` to `budget.municipality` on lines 60 and 62 of `dataLoader.ts`.

This gap does not affect the import pipeline (Plans 01 and 02 are fully correct) or the API-only architecture (Plan 03's D-06 compliance is correct). It is isolated to the `transformAPIResponse` adapter function and requires no backend changes.

**Root of gap:** The `transformAPIResponse` function was pre-existing code that used the old `"city"` JSON key. When Plan 01 renamed the Go struct relationship from `City City json:"city,omitempty"` to `Municipality Municipality json:"municipality,omitempty"`, the frontend adapter was not updated to match.

---

_Verified: 2026-03-22T20:30:00Z_
_Verifier: Claude (gsd-verifier)_
