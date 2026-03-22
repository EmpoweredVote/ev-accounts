# Project Research Summary

**Project:** v2026.3.7 Treasury Tracker Expansion
**Domain:** Multi-jurisdiction municipal budget data visualization — entity switcher, data migration, and EV design token refresh
**Researched:** 2026-03-22
**Confidence:** HIGH

## Executive Summary

This milestone expands the existing Treasury Tracker from a single-city Bloomington-only app to a multi-jurisdiction platform covering 5+ entities (Bloomington IN, Ellettsville IN, Monroe County IN, LA County CA, LA City CA). The architecture is already in place: the Go backend has a working `POST /treasury/import` endpoint, the frontend `dataLoader.ts` already supports a `cityName` parameter and API-first loading with static JSON fallback, and all chart and visualization components are functional. The work is additive: add an `entity_type` field to the schema, migrate existing Bloomington data to Supabase, build the entity switcher UI, write per-jurisdiction import scripts, and apply EV design tokens to UI chrome only.

The recommended approach is backend-first with a strict dependency order: schema changes must deploy before any imports run, the Bloomington migration validates the pipeline before any new jurisdiction is attempted, and Indiana Gateway imports (Ellettsville, Monroe County) can proceed independently from LA data which is a higher-complexity, separate sourcing track. The EV visual refresh is fully independent and can proceed in parallel with any phase. The central architectural decision — and the one most likely to produce irreversible technical debt if deferred — is to add `fiscal_year_start_month` to `treasury.budgets` and the corrected three-column unique index on `treasury.budgets` before any imports run. These two schema fixes are the critical-path gate for the entire milestone.

The primary risks are schema gaps that cause silent data corruption (missing `dataset_type` in the budget unique index; missing `fiscal_year_start_month` before California data is imported), a pipe-delimited format surprise in Indiana Gateway files that silently produces zero-amount rows if the CSV parser is not explicitly configured, and the LA County adopted budget being PDF-primary with no machine-readable download (requiring a fallback to actual expenditure transactions from `data.lacounty.gov`). Each risk has a clear prevention strategy and maps to a specific phase where it must be addressed.

## Key Findings

### Recommended Stack

The only new packages are `tailwindcss` and `@tailwindcss/vite` to bring treasury-tracker in line with all other EV apps, plus a `@chrisandrewsedu/ev-ui` upgrade from the stale `^0.1.6` to `^0.1.53`. No new charting libraries, no state management libraries, and no additional React packages are needed. Import pipeline scripts (Python, Node.js) are one-off data tools — `papaparse` is the only meaningful addition to the dev toolchain, used exclusively in Node.js import scripts.

**Core technologies (new additions only):**
- `tailwindcss ^4.x` + `@tailwindcss/vite`: Tailwind v4 CSS-first setup, identical to essentials and CompassV2; required to consume `ev-ui/tailwind-preset` utilities
- `@chrisandrewsedu/ev-ui ^0.1.53`: Upgrade from stale ^0.1.6; brings correct token values, current SiteHeader, and confirmed `./tailwind-preset` and `./tokens` exports
- `papaparse ^5.5.3`: Import pipeline scripts only (Node.js); replaces hand-rolled CSV parser for Indiana Gateway pipe-delimited files

**Existing stack unchanged:** React 19 + TypeScript + Vite 7.2.4, D3.js ^7.9.0 + Recharts ^3.5.1, Go 1.24 + Chi + GORM, Supabase PostgreSQL.

### Expected Features

The milestone has a clear P1 core and well-defined P2 additions. The feature dependency chain is: `entity_type` backend field → Bloomington migration → entity switcher UI → new jurisdiction imports. LA entities are an independent complexity track from Indiana entities and can run in parallel.

**Must have (P1 — this milestone):**
- `entity_type` field on `treasury.cities` — prevents "Monroe County, City" label confusion from day one; low cost, essential correctness
- Bloomington data migration to Supabase — removes static JSON tech debt; validates the import pipeline before new jurisdictions attempt it
- Entity switcher UI — dropdown showing entities grouped by type; hero image, entity name, and population stat update per selection
- EV visual refresh — ev-coral/ev-muted-blue/ev-yellow applied to UI chrome only; never to chart segment fills
- Ellettsville IN operating budget — Indiana Gateway, same format as Bloomington, low effort
- Monroe County IN operating budget — Indiana Gateway, county entity_type test case
- LA County operating budget — highest complexity; `data.lacounty.gov` expenditures or CEO PDF fallback for top-level figures

**Should have (P2 — after operating budgets validate):**
- LA City operating appropriations via `data.lacity.org` Socrata CSV (FY 2010-2025)
- Per-capita normalization toggle — `formatPerResident()` already exists in App.tsx; needs entity population populated for all jurisdictions

**Defer (v2+):**
- Transaction-level checkbook for LA (millions of rows; requires separate `treasury.transactions` table and paginated API)
- Side-by-side jurisdiction comparison layout
- Year-over-year trend charts
- Revenue and salary data for LA entities

### Architecture Approach

The architecture is a light extension of the existing system. `App.tsx` gains a `selectedEntity` state replacing all hardcoded Bloomington references. `dataLoader.ts` adds `entityType` to its signature and cache key to prevent cross-entity cache collisions. A new `EntitySwitcher.tsx` is a controlled stateless dropdown. On the backend, one model field (`EntityType` on `City`) and two manual SQL migrations (composite unique constraint on budgets; `fiscal_year_start_month` on budgets) precede all other work. All import scripts POST to the existing `POST /treasury/budgets/import` endpoint rather than inserting SQL directly, preserving transaction safety and the recursive category tree builder.

**Major components:**
1. `EntitySwitcher.tsx` (NEW) — controlled dropdown populated from `GET /treasury/cities`; all state owned by App.tsx
2. `App.tsx` (MODIFIED) — owns `selectedEntity: {id, name, state, entityType}` state; drives hero card, breadcrumbs, dataset tabs dynamically
3. `dataLoader.ts` (MODIFIED) — adds `entityType` param; updates cache key to `"entityType:name-year-dataset"`; guards static JSON fallback to Bloomington city only
4. `scrapers/treasury/` (NEW) — Python import scripts per jurisdiction, all POSTing to the existing admin endpoint
5. `src/styles/tokens.ts` (NEW) — thin re-export of ev-ui tokens for D3 color usage (resolved hex values, not CSS variable strings)

### Critical Pitfalls

1. **Missing `dataset_type` in budget unique index** — The `idx_budget_city_year` constraint covers only `(city_id, fiscal_year)`. A second dataset type for the same city/year produces a unique-constraint violation or silent duplicate rows. Fix first: `CREATE UNIQUE INDEX idx_budget_city_year_dataset ON treasury.budgets (city_id, fiscal_year, dataset_type)` before any import runs.

2. **Missing `fiscal_year_start_month` before California imports** — Indiana uses calendar year (Jan-Dec); California uses fiscal year (Jul-Jun). Storing only `fiscal_year: 2025` for both creates false comparability in the UI. Add `fiscal_year_start_month smallint NOT NULL DEFAULT 1` to `treasury.budgets` in Phase 1; set to `7` for all CA entities.

3. **Indiana Gateway pipe-delimiter and encoding** — Gateway files use `|` as delimiter and Windows-1252 encoding, not UTF-8 CSV. Silent misparse produces all-zero amounts with no thrown errors. Prevention: explicit `delimiter='|'` plus UTF-8 re-encoding in every Indiana import script; verify row counts against a manual spot-check before accepting the import.

4. **LA County budget is PDF-first** — `ceo.lacounty.gov` publishes the adopted budget as a multi-volume PDF only. PDF table parsing (pdfminer, tabula, camelot) produces amounts off by 10-40% due to merged cells and footnotes. Use `data.lacounty.gov` actual expenditure transactions instead; accept top-level adopted figures as manual entry from PDF if needed.

5. **EV design tokens applied to chart segment fills** — The 30-color data viz palette provides perceptual distinctiveness across 15+ budget categories. Replacing `--data-*` variables with EV brand tokens collapses the sunburst chart to a single-hue blur. Rule: EV tokens apply to UI chrome only (header, tabs, cards, buttons); `--data-*` visualization namespace is preserved untouched.

## Implications for Roadmap

Based on combined research, the dependency graph suggests 5 phases with two independent parallel tracks (Indiana data vs. LA data) available after the schema foundation is set.

### Phase 1: Schema Foundation and Bloomington Migration
**Rationale:** The unique-index bug and missing `fiscal_year_start_month` field are landmines for every subsequent import. These must be fixed before any data work begins. Bloomington migration both removes tech debt and validates the import pipeline with known-good data before attempting unfamiliar jurisdictions.
**Delivers:** Three-column unique index on `treasury.budgets`; `entity_type` and `fiscal_year_start_month` fields added; all Bloomington operating/revenue/salary data (15 imports: 5 years × 3 datasets) in Supabase; confirmed API-first loading for Bloomington.
**Addresses:** `entity_type` backend field; Bloomington Supabase migration (both P1); checkbook transaction architecture decision
**Avoids:** Missing `dataset_type` unique index; missing `fiscal_year_start_month`; payroll PII import; checkbook transaction volume overwhelming the API

### Phase 2: Indiana Data Import (Ellettsville + Monroe County)
**Rationale:** Indiana Gateway is a single shared format for both entities; high code reuse. Monroe County tests the county `entity_type` path before LA County attempts it. Both entities are lower complexity than LA and validate the parameterized import script against a known data format.
**Delivers:** Ellettsville operating budget (2015-2026); Monroe County operating budget (2012-2025); `entity_type=county` path exercised end-to-end.
**Addresses:** Ellettsville IN data (P1); Monroe County IN data (P1)
**Avoids:** Pipe-delimiter misparse (explicit `delimiter='|'` plus UTF-8 re-encoding); fiscal year type set correctly for Indiana (Jan-Dec, `fiscal_year_start_month = 1`)

### Phase 3: LA Data Research and Import
**Rationale:** LA entities are an independent complexity track with different portals, different format, and much larger scale. Deliberately sequenced after Indiana imports so the import tooling is proven on simpler data first. Budget 2-3 days for data source investigation before writing any parser code.
**Delivers:** LA County operating data from `data.lacounty.gov` actual expenditures (department-level); LA City operating appropriations from `data.lacity.org` Socrata CSV; `fiscal_year_start_month = 7` set for all CA entities.
**Addresses:** LA County data (P1); LA City data (P2)
**Avoids:** PDF-parsing trap (use expenditure transactions, not CEO PDF); fiscal year mismatch CA vs. Indiana

### Phase 4: Entity Switcher Frontend
**Rationale:** The entity switcher is gated on at least two entities in the database. Shipping after Indiana data (minimum 3 entities: Bloomington, Ellettsville, Monroe County) makes it immediately demonstrable across entity types including the county path. The `entity_type` backend field from Phase 1 is a hard dependency.
**Delivers:** `EntitySwitcher.tsx` component; `App.tsx` `selectedEntity` state replacing all hardcoded Bloomington references; data-driven hero card; `dataLoader.ts` updated cache key and entity_type query param; static JSON fallback guarded to Bloomington city only.
**Addresses:** Entity switcher UI (P1)
**Avoids:** `activeTab` not wired to data loading; hardcoded Bloomington hero content; static JSON fallback silently serving Bloomington data for non-Bloomington entity selections

### Phase 5: EV Visual Refresh
**Rationale:** Fully independent of all data work — has zero dependencies on Phases 1-4. Sequenced last to avoid visual churn while data work iterates, but can be moved earlier or run in parallel with any other phase.
**Delivers:** Tailwind v4 installed in treasury-tracker; `@chrisandrewsedu/ev-ui` upgraded to ^0.1.53; `src/index.css` CSS variables aligned to exact ev-ui token values; `DatasetTabs.tsx` color definitions updated to `dataVizPalette`; `src/styles/tokens.ts` re-export for D3 usage; chart segment fills preserved in separate `--data-*` namespace.
**Addresses:** EV visual refresh (P1)
**Avoids:** Brand token vs. data visualization palette collision; hardcoded hex drift from design system

### Phase Ordering Rationale

- Phase 1 is the absolute critical-path gate: the schema fixes cannot be deferred without corrupting or breaking all subsequent imports; Bloomington migration proves the pipeline on known data before unknown data is attempted
- Phases 2 and 3 are independent data tracks that can run in parallel if capacity allows; Indiana (Phase 2) is sequenced first because it validates the tooling at lower complexity before the higher-complexity LA work
- Phase 4 (entity switcher) depends on Phase 1 for the `entity_type` backend model change and on at least two entities existing in the database; it is UI-only and has no dependency on Phase 3
- Phase 5 (visual refresh) has zero dependencies on any other phase and can start any time; it is last only to minimize premature polish churn during data iteration

### Research Flags

Phases likely needing deeper research during planning:

- **Phase 3 (LA Data):** Data source discovery is partially unverified. LA County Socrata dataset IDs on `data.lacounty.gov` are not confirmed; the PDF-vs-expenditure data decision must be made before writing any parser. Budget 2-3 investigative days before any import code is written.
- **Phase 2 (Indiana Gateway format):** Column schema for Ellettsville and Monroe County Gateway files is confirmed at medium confidence only. Download a small sample file and inspect raw bytes before committing to field mappings.

Phases with standard patterns (skip research-phase):

- **Phase 1 (Schema + Bloomington):** All backend files inspected directly; `ImportBudget` handler, model, constraint SQL fully documented. Standard GORM migration pattern. No unknowns.
- **Phase 4 (Entity Switcher):** App.tsx data flow and dataLoader.ts API surface fully documented. Standard React controlled component pattern. `GET /treasury/cities` already exists.
- **Phase 5 (Visual Refresh):** Tailwind v4 CSS-first install is identical to the pattern in essentials and CompassV2. Token export paths confirmed from ev-ui source. No unknowns.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All files inspected directly; Tailwind v4 pattern confirmed in two other EV apps; ev-ui exports verified at source |
| Features | MEDIUM-HIGH | P1 features are well-defined; LA entity sourcing confirmed at medium confidence pending dataset ID verification |
| Architecture | HIGH | All treasury module files inspected directly; build order and integration points fully traced from source |
| Pitfalls | HIGH | Derived from direct codebase inspection including row counts from actual CSV files (27K operating, 282K checkbook, 304K payroll rows confirmed) |

**Overall confidence:** HIGH

### Gaps to Address

- **LA County Socrata dataset IDs:** `data.lacounty.gov` portal existence confirmed but specific downloadable dataset IDs for department-level expenditures need verification before writing the LA County import script. Resolution: 30-minute investigation at the start of Phase 3.
- **Indiana Gateway exact column schema for Ellettsville and Monroe County:** Format is pipe-delimited and DLGF-standard at high confidence, but exact column names for non-Bloomington units were not directly verified by download. Resolution: download one Gateway file for each entity at the start of Phase 2 before writing the transform.
- **Monroe County category depth:** If the Indiana Gateway Monroe County file lacks department-level breakdown, the category hierarchy will be shallower than Bloomington's. Resolution: accept coarser hierarchy if that is all the source data provides; document explicitly in entity metadata rather than forcing a mapping.
- **Checkbook transaction architecture decision:** Phase 1 must decide whether to import Bloomington's 282K checkbook rows to a new `treasury.transactions` table or drop transaction-level detail entirely for this milestone. Recommendation from research: keep checkbook aggregated at top-N vendors per category; defer row-level transactions to v2+.

## Sources

### Primary (HIGH confidence)
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/treasury/` — models.go, handlers.go, routes.go, setup.go (full inspection)
- `/Users/chrisandrews/Documents/GitHub/treasury-tracker/src/` — App.tsx, dataLoader.ts, budget.ts, index.css, DatasetTabs.tsx, budgetConfig.json (full inspection)
- `/Users/chrisandrews/Documents/GitHub/ev-ui/src/tokens.js` (v0.1.53) and `tailwind-preset.js` — token values and export paths confirmed
- `/Users/chrisandrews/Documents/GitHub/essentials/src/index.css` — Tailwind v4 CSS-first pattern confirmed as the EV standard
- `treasury-tracker/data/` — operating_budget-all.csv (27,804 rows), checkbook-all.csv (282,458 rows), payroll-all.csv (304,911 rows) — row counts confirmed by direct inspection

### Secondary (MEDIUM confidence)
- `https://gateway.ifionline.org/public/download.aspx` — pipe-delimited format documented; exact column schema for Ellettsville/Monroe County not directly downloaded and inspected
- `https://data.lacity.org/Administration-Finance/Open-Budget-Appropriations-Fiscal-Years-2010-2025/5242-pnmt` — LA City CSV download confirmed
- `https://budget.lacounty.gov/` — ArcGIS-backed LA County budget explorer confirmed; Socrata dataset IDs on data.lacounty.gov not yet verified
- `https://budgetnotices.in.gov/Unit_View.aspx?unit_id=2546` — Ellettsville budget years 2015-2026 confirmed available

### Tertiary (LOW confidence)
- LA County `data.lacounty.gov` Open Expenditures dataset — existence confirmed; field schema not directly inspected; treat as needing verification at Phase 3 start

---
*Research completed: 2026-03-22*
*Ready for roadmap: yes*
