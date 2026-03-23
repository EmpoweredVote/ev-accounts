# Phase 94: LA Data Import - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-22
**Phase:** 94-la-data-import
**Areas discussed:** Data source strategy, Category hierarchy mapping, Dataset scope & years, Importer architecture

---

## Data Source Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Socrata CSV export URL | Simple HTTP GET, returns full CSV, no API key needed. Mirrors Gateway approach. | ✓ |
| SODA API with pagination | Structured JSON responses with server-side filtering. More complex. | |
| Manual CSV download | Download CSVs manually, point importer at local files. | |

**User's choice:** Socrata CSV export URL
**Notes:** None

| Option | Description | Selected |
|--------|-------------|----------|
| Config-driven | Add LA entities to treasury-import-config.json with dataset_id, base_url, column mappings. | ✓ |
| Hardcoded per entity | Separate Go functions per LA entity with hardcoded dataset IDs. | |

**User's choice:** Config-driven
**Notes:** None

| Option | Description | Selected |
|--------|-------------|----------|
| Researcher finds them | Phase researcher agent investigates portals to identify correct datasets. | ✓ |
| I have them already | User provides dataset IDs directly. | |

**User's choice:** Researcher finds them
**Notes:** Dataset ID research is a prerequisite blocker from STATE.md.

---

## Category Hierarchy Mapping

| Option | Description | Selected |
|--------|-------------|----------|
| Config-driven column list | hierarchy_columns in config lists LA columns in order. Same pattern as Gateway. | ✓ |
| Fixed two-level: dept → line items | Flatten to department-level categories. Simpler but loses granularity. | |
| Researcher decides based on data | Let researcher inspect actual CSV columns and recommend. | |

**User's choice:** Config-driven column list
**Notes:** None

| Option | Description | Selected |
|--------|-------------|----------|
| Full tree from config | Import whatever columns are listed. Frontend handles arbitrary depth. | ✓ |
| Cap at 3 levels | Limit to 3 levels max. Keeps UI manageable. | |
| You decide | Claude's discretion based on actual data. | |

**User's choice:** Full tree from config
**Notes:** None

---

## Dataset Scope & Years

| Option | Description | Selected |
|--------|-------------|----------|
| Expenditures only | Requirements specify expenditure/appropriations only. Revenue deferred (REV-01). | |
| Mirror Bloomington (3 types) | Operating/expenditures, revenue, salaries — full parity. | ✓ |
| Whatever's available | Import all dataset types the portal offers. | |

**User's choice:** Mirror Bloomington (custom response)
**Notes:** User wants to mirror Bloomington's full coverage: money coming in, money going out, salaries. Individual expenditures/receipts discussed but kept deferred per milestone decision (TXNS-01).

| Option | Description | Selected |
|--------|-------------|----------|
| Keep deferral — 3 types only | Stick with milestone decision. Transactions stay in v2+. | ✓ |
| Add transactions if easy | Include if straightforward, defer if complex. | |
| Revise — include transactions | Override deferral, add transaction-level data. | |

**User's choice:** Keep deferral — 3 types only
**Notes:** None

| Option | Description | Selected |
|--------|-------------|----------|
| Match Bloomington: 2021-2025 | Same 5-year window. CA fiscal years run July-June. | ✓ |
| Researcher decides | Check portal availability and recommend range. | |
| All available years | Import everything regardless of range. | |

**User's choice:** Match Bloomington: 2021-2025
**Notes:** None

---

## Importer Architecture

| Option | Description | Selected |
|--------|-------------|----------|
| Unified config, separate fetchers | One config file with source_type field. Shared tree builder and DB logic. | ✓ |
| Separate importer function | New ImportSocrataBudgets alongside ImportGatewayBudgets. Some duplication. | |
| Full abstraction layer | DataSource interface with Gateway/Socrata implementations. | |

**User's choice:** Unified config, separate fetchers
**Notes:** None

| Option | Description | Selected |
|--------|-------------|----------|
| Extend import-budgets | Add --source=socrata alongside --source=gateway. One command. | ✓ |
| New subcommand: import-la | Separate CLI subcommand for LA data. | |

**User's choice:** Extend import-budgets
**Notes:** None

---

## Claude's Discretion

- Socrata fetch implementation details (timeouts, error handling, content-type validation)
- Config field naming for Socrata-specific properties
- Shared logic refactoring between Gateway and Socrata tree builders

## Deferred Ideas

- Transaction-level/checkbook data for LA entities — deferred to v2+ (TXNS-01)
