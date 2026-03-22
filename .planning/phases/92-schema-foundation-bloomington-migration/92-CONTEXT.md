# Phase 92: Schema Foundation & Bloomington Migration - Context

**Gathered:** 2026-03-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix critical treasury schema gaps (three-column budget unique index, entity_type on municipalities, fiscal_year_start_month) and migrate all Bloomington budget data from static JSON to Supabase. This clears the critical-path gate for all subsequent data imports (Phases 93-94).

</domain>

<decisions>
## Implementation Decisions

### Migration Approach
- **D-01:** Use a Go CLI subcommand (`import-budgets`) in EV-Backend, consistent with existing `import-stances` and `import-quotes` patterns. Reads static JSON files, transforms to treasury GORM models, upserts via GORM.
- **D-02:** Migrate all three dataset types (operating, revenue, salaries) together in this phase. Requirements DATA-01 through DATA-03 all land here.
- **D-03:** Validate migration via API round-trip check — after import, hit treasury API endpoints and compare totals/category counts against source JSON to confirm the full stack works.

### Entity Type Modeling
- **D-04:** Rename `City` model to `Municipality`, table from `treasury.cities` to `treasury.municipalities`, FK from `city_id` to `municipality_id`. User chose "Municipality" as more accurate than "City" for an entity that covers cities, counties, and townships.
- **D-05:** Support three entity_type values: `city`, `county`, `township`. Composite unique constraint on `(name, state, entity_type)`.

### Static Fallback Guard
- **D-06:** Remove the static JSON fallback from `dataLoader.ts` entirely — no static files, no mock data fallback. Once data is in Supabase, the API is the sole data source.
- **D-07:** When API is unavailable, show an error message with a retry button. No empty dashboard shell.

### Schema Migration Safety
- **D-08:** Use GORM AutoMigrate for new fields and indexes, consistent with all other EV-Backend modules. The table rename (`cities` → `municipalities`) and FK rename (`city_id` → `municipality_id`) require a manual SQL step run before deploying the updated code.
- **D-09:** Apply table/FK rename via `ALTER TABLE treasury.cities RENAME TO treasury.municipalities` + column rename, then deploy new Go code with updated model that AutoMigrates remaining changes.

### Claude's Discretion
- None — all areas discussed with explicit user decisions.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Backend Models
- `EV-Backend/internal/treasury/models.go` — Current City/Budget/BudgetCategory/BudgetLineItem GORM models (to be modified)
- `EV-Backend/internal/treasury/handlers.go` — Current API handlers (city_id references need updating)
- `EV-Backend/internal/treasury/routes.go` — Current API routes (endpoint naming)
- `EV-Backend/internal/treasury/setup.go` — AutoMigrate setup

### Frontend Data Loading
- `treasury-tracker/src/data/dataLoader.ts` — Current three-tier fallback (API → static JSON → mock) to be simplified to API-only with error state
- `treasury-tracker/src/data/budgetData.ts` — Mock/static data to be removed

### Existing CLI Patterns
- `EV-Backend/cmd/` — Existing CLI subcommands (import-stances, import-quotes) as reference pattern for import-budgets

### Requirements
- `.planning/REQUIREMENTS.md` — SCHM-01, SCHM-02, SCHM-03, DATA-01, DATA-02, DATA-03, DATA-04

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `EV-Backend/cmd/` CLI pattern — existing `import-stances` and `import-quotes` subcommands provide the template for `import-budgets`
- Treasury GORM models — well-structured with hierarchical categories, line items, and proper table name methods
- `dataLoader.ts` cache system — cache key structure (`${cityName}-${year}-${dataset}`) already supports multi-entity; just needs the static fallback removed

### Established Patterns
- All backend modules use GORM AutoMigrate on startup for schema changes
- Treasury API uses two-step fetch pattern: get budget list, then get categories by budget ID
- FK relationships use `uuid.UUID` types with GORM tags

### Integration Points
- `treasury-tracker/src/data/dataLoader.ts` — main data entry point, needs static fallback removed and error state added
- `EV-Backend/main.go` — CLI command registration
- `EV-Backend/internal/treasury/routes.go` — API endpoint paths may need updating if city → municipality naming changes route paths

</code_context>

<specifics>
## Specific Ideas

- User wants "Municipality" naming specifically — not "Local", not "Entity", not keeping "City". This was a deliberate choice for semantic accuracy.
- The rename from City → Municipality ripples through: model name, table name, FK column name, API route paths, handler variable names, and frontend API calls. Plan should account for all these touchpoints.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 92-schema-foundation-bloomington-migration*
*Context gathered: 2026-03-22*
