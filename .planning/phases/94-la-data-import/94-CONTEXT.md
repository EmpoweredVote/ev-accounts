# Phase 94: LA Data Import - Context

**Gathered:** 2026-03-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Import LA County and LA City budget data from Socrata open data portals (data.lacounty.gov, data.lacity.org) into Supabase, with fiscal_year_start_month=7 for all California entities. Covers three dataset types per entity (operating/expenditures, revenue, salaries) for fiscal years 2021-2025 where available.

</domain>

<decisions>
## Implementation Decisions

### Data Source Strategy
- **D-01:** Use Socrata CSV export URLs (`/api/views/{id}/rows.csv?accessType=DOWNLOAD`) — simple HTTP GET, returns full CSV, no API key needed for public datasets. Mirrors the Gateway approach of fetching raw CSV.
- **D-02:** Config-driven — add LA entities to `treasury-import-config.json` with `source_type: "socrata"`, `dataset_id`, `base_url`, and column mappings. Consistent with the Gateway entity config pattern.
- **D-03:** Researcher agent must identify the correct Socrata dataset IDs for department-level expenditures (LA County) and operating appropriations (LA City) during research phase. This was flagged as a blocker in STATE.md.

### Category Hierarchy Mapping
- **D-04:** Config-driven column list via `hierarchy_columns` — same pattern as Gateway. The config lists LA-specific columns in order (e.g., `["department", "program", "account"]`), and the existing `buildGatewayCategoryTree` logic (or its Socrata equivalent) builds the tree from those columns.
- **D-05:** Full tree depth from config — no artificial cap. If the config lists 4 hierarchy levels, build 4 levels. The frontend already handles arbitrary depth.

### Dataset Scope & Years
- **D-06:** Mirror Bloomington's three dataset types: operating/expenditures, revenue, and salaries. Import all three for each LA entity where available on the portal.
- **D-07:** Transaction-level/checkbook data remains deferred to v2+ per milestone decision (TXNS-01 in REQUIREMENTS.md).
- **D-08:** Fiscal year range: 2021-2025, matching Bloomington and Indiana. California fiscal years run July-June (FY2025 = Jul 2024 – Jun 2025).

### Importer Architecture
- **D-09:** Unified config file (`treasury-import-config.json`) with a `source_type` field per entity — `"gateway"` for Indiana, `"socrata"` for LA. Shared category tree builder and DB insertion logic. Only the HTTP fetch layer differs between sources.
- **D-10:** Extend the existing `import-budgets` CLI with `--source=socrata` alongside `--source=gateway`. One command, source flag routes to the right fetcher.

### Claude's Discretion
- Socrata fetch implementation details (timeouts, error handling, content-type validation)
- Config field naming for Socrata-specific properties (dataset_id, base_url pattern)
- How to refactor shared logic between Gateway and Socrata tree builders (extract common function vs. duplicate with minor differences)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Backend Models & Importer
- `EV-Backend/internal/treasury/models.go` — Municipality, Budget, BudgetCategory, BudgetLineItem GORM models
- `EV-Backend/internal/treasury/importer.go` — ImportBudgets (JSON), ImportGatewayBudgets, buildGatewayCategoryTree, GatewayConfig/GatewayEntityConfig structs
- `EV-Backend/internal/treasury/gateway_test.go` — Test patterns for the Gateway importer
- `EV-Backend/internal/treasury/setup.go` — AutoMigrate setup
- `EV-Backend/main.go` — CLI command registration (import-budgets with --source flag)

### Config
- `EV-Backend/treasury-import-config.json` — Existing Gateway entity configs for Ellettsville and Monroe County (extend with LA entities)

### Requirements
- `.planning/REQUIREMENTS.md` — LA-01, LA-02, LA-03

### Prior Phase Context
- `.planning/phases/92-schema-foundation-bloomington-migration/92-CONTEXT.md` — Schema decisions, Municipality model, idempotent import pattern
- `.planning/phases/93-indiana-data-import/93-CONTEXT.md` — Gateway import pipeline, config-driven approach, hierarchy tree building

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ImportGatewayBudgets` orchestration — transaction-per-entity, idempotent check, municipality find-or-create, category tree insertion. Core logic reusable for Socrata source.
- `buildGatewayCategoryTree` — builds BudgetCategory hierarchy from configurable column names. Can be generalized or duplicated for Socrata CSV columns.
- `newGatewayCSVReader` — wraps Windows-1252 → UTF-8 decoding. Socrata serves UTF-8 natively so this won't be needed, but the CSV reader pattern is reusable.
- `GatewayEntityConfig` struct — template for Socrata entity config fields (display_name, state, entity_type, fiscal_years, hierarchy_columns, amount_column).

### Established Patterns
- Config-driven entity metadata in `treasury-import-config.json`
- Transaction-per-import with rollback on error
- Idempotent import: check (municipality_id, fiscal_year, dataset_type) before insert
- `FiscalYearStartMonth` set per entity in config (1 for Indiana, 7 for California)

### Integration Points
- `treasury-import-config.json` — add `socrata_entities` array alongside existing `gateway_entities`
- `main.go` CLI registration — add `--source=socrata` option to import-budgets
- `importer.go` — new `ImportSocrataBudgets` function parallel to `ImportGatewayBudgets`

</code_context>

<specifics>
## Specific Ideas

- User wants to mirror Bloomington's full data coverage (operating + revenue + salaries) for LA entities — not just the minimum expenditure data from requirements.
- The Socrata dataset ID research is a prerequisite blocker — must be resolved before planning can produce concrete task specs.
- Config should support multiple dataset_ids per entity (one per dataset type: expenditures, revenue, salaries) since each may be a separate Socrata dataset.

</specifics>

<deferred>
## Deferred Ideas

- Transaction-level/checkbook data for LA entities — deferred to v2+ (TXNS-01)

</deferred>

---

*Phase: 94-la-data-import*
*Context gathered: 2026-03-22*
