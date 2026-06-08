# Phase 107: DC Finance - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-08
**Phase:** 107-DC Finance
**Areas discussed:** DC OCF strategy, EHN FEC script scope

---

## DC OCF Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Research-first, ingest if accessible | Pre-flight ocf.dc.gov — ingest if API/bulk download exists; document + close if not | ✓ |
| Documentation-only | Research what OCF exposes, write a finding, close DCFI-02 — no ingestion attempt | |
| Full scraper attempt | Build HTML parser for ocf.dc.gov even if no API exists | |

**User's choice:** Research-first, ingest if accessible

**Follow-up — accessibility threshold:**

| Option | Description | Selected |
|--------|-------------|----------|
| API or bulk download only | REST API, JSON endpoint, or downloadable CSV/dataset; HTML-only = not accessible | ✓ |
| Any parseable format | Attempt ingestion even from HTML tables or paginated search | |
| You decide | Executor uses judgment | |

**User's choice:** API or bulk download only

**Follow-up — finance_summary shape for OCF data:**

| Option | Description | Selected |
|--------|-------------|----------|
| Match FEC shape where possible | Use {total_raised, top_donors, cycle, source: 'DC_OCF'}; fill what's available | ✓ |
| OCF-native fields | Use OCF's own field names; frontend must handle variance | |
| You decide | Executor adapts to what OCF provides | |

**User's choice:** Match FEC shape where possible

**Notes:** If OCF has no accessible structured data, document the finding and close DCFI-02. No scraper attempt unless there's a clean structured target.

---

## EHN FEC Script Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Targeted EHN-only pass | New script ehn-fec-finance.ts; fast, surgical, no risk to existing politicians | ✓ |
| Run full run-fec-finance-summary.ts | Processes all ~535 federal politicians; slower; overwrites existing data | |
| Run full script with NULL-only filter | Modify existing script to skip non-null; re-run | |

**User's choice:** Targeted EHN-only pass

**Follow-up — delivery mechanism:**

| Option | Description | Selected |
|--------|-------------|----------|
| New script ehn-fec-finance.ts | Standalone script hardcoded to EHN's UUID; same FEC API pattern | ✓ |
| Extend run-fec-finance-summary.ts with --politician flag | Add flag to existing script; more reusable | |
| You decide | Executor picks simplest approach | |

**User's choice:** New script ehn-fec-finance.ts

**Notes:** EHN UUID = 4dbc8de1-9984-42a5-b2aa-5445bf0619b9, bioguide_id = N000147. Three-step FEC pattern (candidates/search → totals → by_employer). Write directly to DB via pool.query().

---

## Claude's Discretion

- **Plan structure**: 1 plan with 2 sequential tasks (T1 = EHN FEC, T2 = DC OCF) — user confirmed "ready for context" without requesting 2-plan discussion, so 1 plan is the implementation choice.
- **Script minimalism**: `ehn-fec-finance.ts` can be a minimal targeted script — no need to build a general-purpose framework.
- **OCF finding format**: if documenting "no accessible data," executor decides between migration comment or standalone assessment file.

## Deferred Ideas

- **FEC name-match queue** (fix-fec-name-mismatches.ts follow-up for 11 senators/House members with NULL finance_summary) — separate quick task, not Phase 107 scope.
- **Finance data for Shadow Senators + SBOE** via DC OCF — out of v2.8 scope; could extend if DCFI-02 finds accessible OCF data.
