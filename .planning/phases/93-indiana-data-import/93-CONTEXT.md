# Phase 93: Indiana Data Import - Context

**Gathered:** 2026-03-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Import Ellettsville and Monroe County budget data from Indiana Gateway into Supabase, validating the parameterized import pipeline on the pipe-delimited Indiana Gateway CSV format. This phase extends the existing `import-budgets` CLI to handle a new data source (Indiana Gateway) beyond the original Bloomington JSON files.

</domain>

<decisions>
## Implementation Decisions

### Data Acquisition
- **D-01:** Automated fetch — the importer downloads CSV data directly from Indiana Gateway URLs at runtime. No manual file download step.
- **D-02:** Fetch is built into the `import-budgets` CLI command (via a source/format parameter), not a separate download step. One command fetches and imports.
- **D-03:** Validate column headers before processing rows. Fail fast with a clear error if the expected columns are missing or the format has changed.

### Import Pipeline
- **D-04:** Extend the existing `ImportBudgets` function with a source/format parameter. JSON path for Bloomington, Gateway fetch+parse for Indiana entities. Shared municipality lookup and category insertion logic.
- **D-05:** Build hierarchy tree from CSV columns — use the Gateway's fund > department > account columns as hierarchy levels. Each unique combination becomes a BudgetCategory with parent references, matching the existing tree structure.
- **D-06:** Delimiter is configurable per source via `ImportBudgetsConfig`. Gateway defaults to pipe (`|`), but the config supports other delimiters for future sources.

### Entity Creation
- **D-07:** Entity metadata (name, state, entity_type, Gateway URL, delimiter, hierarchy column mappings) lives in a treasury-specific config file (e.g., `treasury-import-config.json`). Separate from the essentials `pipeline_config.json`.
- **D-08:** Config controls the display name directly — "Monroe County" is stored as the municipality name, not derived from entity_type + "Monroe". What's in the config is what's stored and displayed.

### Dataset Scope
- **D-09:** Import all available dataset types (operating, revenue, and any others the Gateway provides), not just operating. Expand beyond the minimum requirements.
- **D-10:** Fiscal year coverage matches Bloomington: 2021-2025. Skip older data even if available on the Gateway.

### Claude's Discretion
- Pipeline config file structure and field naming
- HTTP client details for Gateway fetch (timeouts, retries, user-agent)
- UTF-8 re-encoding implementation approach

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Backend Models & Importer
- `EV-Backend/internal/treasury/models.go` — Municipality, Budget, BudgetCategory, BudgetLineItem GORM models
- `EV-Backend/internal/treasury/importer.go` — Existing ImportBudgets function (JSON-based, to be extended)
- `EV-Backend/internal/treasury/handlers.go` — API handlers with importCategories helper (reusable for CSV tree building)
- `EV-Backend/internal/treasury/setup.go` — AutoMigrate setup
- `EV-Backend/main.go` — CLI command registration (lines 154-170 for import-budgets)

### Existing Import Patterns
- `EV-Backend/cmd/bulk-import/` — Deprecated bulk import (reference only)

### Requirements
- `.planning/REQUIREMENTS.md` — IND-01, IND-02, IND-03

### Prior Phase Context
- `.planning/phases/92-schema-foundation-bloomington-migration/92-CONTEXT.md` — Schema decisions, Municipality model, idempotent import pattern

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ImportBudgets` function — orchestration pattern (transaction per file, idempotent check, municipality find-or-create) directly reusable for Gateway source
- `importCategories` recursive helper — already handles hierarchical BudgetCategory insertion with parent references
- `budgetJSON` struct — reference for how Bloomington data maps to models (Gateway CSV needs equivalent mapping)
- Municipality model with entity_type — already supports city/county/township

### Established Patterns
- CLI subcommands registered in `main.go` with flag parsing
- Transaction-per-import with rollback on error
- Idempotent import: check (municipality_id, fiscal_year, dataset_type) before insert
- `FiscalYearStartMonth = 1` hardcoded for Indiana entities

### Integration Points
- `main.go` CLI registration — add Gateway source flag/parameter to import-budgets
- `ImportBudgetsConfig` struct — extend with source type, delimiter, config file path
- Treasury API endpoints — no changes needed (already serve any municipality data)

</code_context>

<specifics>
## Specific Ideas

- Config file approach mirrors the essentials `pipeline_config.json` pattern the user is familiar with — a treasury-specific equivalent for repeatable imports
- "Monroe County" must display exactly as "Monroe County" — the config-controlled name avoids any derivation bugs (success criterion #2)
- Success criterion #3 explicitly requires "pipe-delimiter and UTF-8 re-encoding" — these must be visible in the code, not implicit

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 93-indiana-data-import*
*Context gathered: 2026-03-22*
