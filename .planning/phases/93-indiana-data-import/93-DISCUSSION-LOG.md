# Phase 93: Indiana Data Import - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-22
**Phase:** 93-indiana-data-import
**Areas discussed:** Data acquisition, Import pipeline, Entity creation, Dataset scope

---

## Data Acquisition

| Option | Description | Selected |
|--------|-------------|----------|
| Manual download | Download CSVs from Indiana Gateway website, place in directory, importer reads local files | |
| Automated fetch | Importer downloads from Indiana Gateway URL at runtime | ✓ |
| Commit to repo | Download CSVs and commit them to the repo like Bloomington JSON files | |

**User's choice:** Automated fetch
**Notes:** None

### Follow-up: Fetch design

| Option | Description | Selected |
|--------|-------------|----------|
| Built into CLI | import-budgets accepts source flag, fetches CSV, then imports. One command. | ✓ |
| Separate download step | Separate CLI command downloads CSVs, then import-budgets reads from directory | |

**User's choice:** Built into CLI

### Follow-up: Header validation

| Option | Description | Selected |
|--------|-------------|----------|
| Validate headers | Check expected columns exist before processing. Fail fast with clear error. | ✓ |
| Trust format | Assume format matches expectations. Simpler but silent misparse risk. | |
| You decide | Claude's discretion | |

**User's choice:** Validate headers

---

## Import Pipeline

| Option | Description | Selected |
|--------|-------------|----------|
| Extend ImportBudgets | Add source/format parameter. JSON for Bloomington, Gateway fetch+parse for Indiana. Shared logic. | ✓ |
| Separate function | New ImportFromGateway function with own entry point. Cleaner separation but some duplication. | |
| You decide | Claude's discretion | |

**User's choice:** Extend ImportBudgets

### Follow-up: Hierarchy mapping

| Option | Description | Selected |
|--------|-------------|----------|
| Build tree from columns | Use fund > department > account as hierarchy levels. BudgetCategory with parent refs. | ✓ |
| Flat categories only | Each row as top-level BudgetCategory. No nesting. | |
| You decide | Claude's discretion | |

**User's choice:** Build tree from columns

### Follow-up: Delimiter config

| Option | Description | Selected |
|--------|-------------|----------|
| Configurable per source | ImportBudgetsConfig gets Delimiter field. Gateway defaults to pipe. | ✓ |
| Hardcoded for Gateway | Gateway parser always uses pipe. | |
| You decide | Claude's discretion | |

**User's choice:** Configurable per source

---

## Entity Creation

| Option | Description | Selected |
|--------|-------------|----------|
| CLI flags | Explicit --entity-name, --entity-type, --state per invocation | |
| Infer from Gateway data | Extract entity name/type from CSV metadata or URL structure | |
| Config file | JSON/YAML config mapping entity IDs to municipality metadata | ✓ |

**User's choice:** Config file

### Follow-up: Config style

| Option | Description | Selected |
|--------|-------------|----------|
| Treasury-specific | treasury-import-config.json with source URLs, entity metadata, delimiter, hierarchy mappings | ✓ |
| Extend pipeline_config.json | Add treasury entries to existing essentials config | |
| You decide | Claude's discretion | |

**User's choice:** Treasury-specific

### Follow-up: Display name

| Option | Description | Selected |
|--------|-------------|----------|
| Config controls name | Config "name" field set to "Monroe County" exactly. Stored and displayed as-is. | ✓ |
| Derive from type | Store name="Monroe" with entity_type="county", frontend appends type for display | |

**User's choice:** Config controls name

---

## Dataset Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Operating only | Stick to IND-01/IND-02 requirements | |
| All available datasets | Import operating, revenue, and any others the Gateway provides | ✓ |
| Operating + revenue | Middle ground — revenue complements operating | |

**User's choice:** All available datasets

### Follow-up: Year range

| Option | Description | Selected |
|--------|-------------|----------|
| All available years | Import whatever fiscal years Gateway has | |
| Match Bloomington (2021-2025) | Only 2021-2025 for consistency | ✓ |
| You decide | Claude's discretion | |

**User's choice:** Match Bloomington (2021-2025)

---

## Claude's Discretion

- Pipeline config file structure and field naming
- HTTP client details for Gateway fetch (timeouts, retries, user-agent)
- UTF-8 re-encoding implementation approach

## Deferred Ideas

None — discussion stayed within phase scope
