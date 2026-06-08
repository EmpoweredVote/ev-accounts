---
phase: 107-dc-finance
plan: "01"
subsystem: finance-ingestion
tags:
  - fec
  - finance
  - dc
  - ocf
  - ingestion
dependency_graph:
  requires:
    - "105-01 (EHN politician record UUID 4dbc8de1-...)"
  provides:
    - "EHN finance_summary populated with FEC 2026 data"
    - "DC OCF accessibility assessment (DCFI-02 closed)"
  affects:
    - "essentials.politicians.finance_summary (EHN row)"
    - "GET /api/essentials/politicians/:id (EHN response now non-null)"
tech_stack:
  added: []
  patterns:
    - "Single-politician FEC ingestion script (ehn-fec-finance.ts)"
    - "YAML crosswalk: bioguide_id N000147 -> H-prefix FEC candidate ID"
    - "Committee ID fallback: /candidate/{id}/committees/ for delegates"
key_files:
  created:
    - backend/scripts/ehn-fec-finance.ts
    - .planning/phases/107-dc-finance/107-OCF-ASSESSMENT.md
  modified: []
decisions:
  - "D-01: Single-politician targeted script — no full-roster loop"
  - "D-02: Three-step FEC fetch with committee fallback for delegates"
  - "D-04/D-05: Research-first OCF assessment — Branch B (no accessible API)"
metrics:
  duration: "13m 40s"
  completed_date: "2026-06-08T15:58:49Z"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 0
---

# Phase 107 Plan 01: DC Finance — EHN FEC Ingestion + OCF Assessment Summary

EHN's `finance_summary` populated with FEC 2026 cycle data ($53,774.80 raised, 1 top donor); DC OCF assessed and DCFI-02 closed via Branch B finding (HTML-only search interface, no REST API or bulk download exists).

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Build and run ehn-fec-finance.ts targeted FEC ingestion (DCFI-01) | `489f0fd` | `backend/scripts/ehn-fec-finance.ts` |
| 2 | Assess DC OCF and document finding (DCFI-02 Branch B) | `5bbf985` | `.planning/phases/107-dc-finance/107-OCF-ASSESSMENT.md` |

## Verification Results

**DCFI-01 DB query:**
```sql
SELECT finance_summary FROM essentials.politicians WHERE id = '4dbc8de1-9984-42a5-b2aa-5445bf0619b9';
```
Result: `{ source: 'FEC', cycle: '2026', total_raised: 53774.8, top_donors: [{ employer: 'TGV ROCKETS', amount: 1000, count: 1 }] }`

**DCFI-02 assessment:** `107-OCF-ASSESSMENT.md` exists, references `DCFI-02`, references `ocf.dc.gov`, documents 10 URLs probed, states explicit closure disposition (Branch B).

**No new npm packages:** `git diff backend/package.json backend/package-lock.json` returns empty (script reuses existing `js-yaml`, `pg`, `dotenv`).

## Task 1 Details: EHN FEC Ingestion

`backend/scripts/ehn-fec-finance.ts` is a targeted single-politician adaptation of `run-fec-finance-summary.ts`. Key characteristics:

- Hardcoded constants: `EHN_POLITICIAN_UUID = '4dbc8de1-9984-42a5-b2aa-5445bf0619b9'`, `EHN_BIOGUIDE_ID = 'N000147'`, `FEC_CYCLE = '2026'`
- YAML crosswalk: fetches `legislators-current.yaml` from unitedstates/congress-legislators, finds `id.bioguide === 'N000147'`, returns H-prefix FEC ID (`H0DC00058`)
- Committee ID: resolved via `/candidates/search/` → committee `C00244335` (no fallback needed; principal_committees was populated)
- 4× `AbortSignal.timeout(30_000)` (FEC fetches) + 1× `AbortSignal.timeout(60_000)` (YAML fetch)
- Rate limiting: 1500ms sleep before each FEC API call
- DB write: parameterized `pool.query('UPDATE essentials.politicians SET finance_summary = $1::jsonb WHERE id = $2', [json, uuid])`
- Dual `pool.end()` calls: success path + fatal catch
- No `apiKey` logged (T-107-03 compliant)

**Run result:**
```
[ehn-fec-finance] FEC candidate ID: H0DC00058
[ehn-fec-finance] Committee ID: C00244335
[ehn-fec-finance] Total raised: $53,774.80
[ehn-fec-finance] Top donors: 1 entries
[ehn-fec-finance] finance_summary written.
```

Note: EHN's 2026 fundraising appears limited (she is largely unopposed as DC's non-voting delegate). The $53,774.80 total and single employer donor (`TGV ROCKETS`, $1,000) are consistent with a non-competitive cycle. This is real FEC data, not a placeholder.

## Task 2 Details: DC OCF Assessment

**Branch B** — no accessible machine-readable interface found.

10 URLs probed across `ocf.dc.gov` and `opendata.dc.gov`. Key findings:

- `ocf.dc.gov/page/data-and-reports` — all access points lead to the EFTS HTML search UI (Electronic Filing and Tracking System); no downloadable JSON/CSV
- `ocf.dc.gov/service/view-contributions-expenditures` — "Search Contributions and Expenditures" links to an HTML form, not an API
- `ocf.dc.gov/service/financial-reports` — image archives of scanned documents (PDFs) and biennial PDF reports; no bulk export
- `opendata.dc.gov` — no OCF campaign finance datasets published in the DC Open Data catalog
- `hub.arcgis.com/api/v3/search?q=campaign+finance+washington+dc` — no OCF datasets found
- `ocf.dc.gov/api`, `ocf.dc.gov/page/developer-resources` — HTTP 404 (no developer access layer exists)

**No `dc-ocf-finance.ts` created. `essentialsService.ts` is unchanged (no `DC_OCF` union added).**

## Deviations from Plan

None — plan executed exactly as written. Task 1 took one clean run; the committee lookup returned a populated `principal_committees` so the fallback endpoint was not needed. Task 2 assessed per D-04/D-05 and correctly classified as Branch B.

## Known Stubs

None — `finance_summary` for EHN contains real FEC API data. DC officials (Mayor Bowser, DC Council) continue to have `finance_summary = null` as expected given the OCF Branch B finding.

## Threat Surface Scan

No new network endpoints, auth paths, or trust boundaries introduced. `ehn-fec-finance.ts` is an operator-run script; it does not expose an API route. All threat model mitigations verified:

- T-107-01/T-107-04: parameterized `pool.query` with explicit `::jsonb` cast; numeric coercion on all FEC fields
- T-107-03: `apiKey` passed only via `URLSearchParams`, never logged
- T-107-05: 1500ms sleep before every FEC call
- T-107-06: `source: 'FEC'` literal in every finance_summary row
- T-107-SC: no new packages (confirmed via `package.json` diff)

## Follow-ups (Deferred)

- FEC name-match queue cleanup: 11 senators/House members with NULL `finance_summary` due to committee lookup failure — fix in `fix-fec-name-mismatches.ts` (separate quick task, out of Phase 107 scope)
- Finance data for DC Shadow Senators (Paul Strauss, Ankit Jain) and SBOE members: these officials have DC OCF filings, not FEC. With OCF inaccessible, this remains open for a future phase if DC OCF ever provides machine-readable data.

## Self-Check: PASSED

- `backend/scripts/ehn-fec-finance.ts` — FOUND
- `.planning/phases/107-dc-finance/107-OCF-ASSESSMENT.md` — FOUND
- Commit `489f0fd` — EHN FEC ingestion script
- Commit `5bbf985` — OCF assessment doc
- DB assertion: `SELECT finance_summary ... WHERE id = '4dbc8de1-...'` returns `source='FEC'`, `cycle='2026'`, `total_raised=53774.8`, `top_donors=[...]` — VERIFIED
