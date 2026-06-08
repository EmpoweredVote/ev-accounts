# Phase 107: DC Finance - Context

**Gathered:** 2026-06-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 107 populates `finance_summary` on DC officials' politician records. Two requirements:
- **DCFI-01**: Eleanor Holmes Norton gets FEC finance data via a new targeted script (`ehn-fec-finance.ts`)
- **DCFI-02**: DC OCF data for Mayor + DC Council — assess ocf.dc.gov, ingest if a REST API or bulk download exists, document + close with finding if not

No new schema changes. No API contract changes (finance_summary already surfaces on `GET /api/essentials/politicians/:id`). Depends on Phase 105 politician records (all confirmed present with `finance_summary = NULL`).

**Requirements in scope:** DCFI-01, DCFI-02
**Out of scope:** Finance data for SBOE members, Shadow Senators (Paul Strauss, Ankit Jain), stances, schema changes.

</domain>

<decisions>
## Implementation Decisions

### EHN FEC Ingestion

- **D-01:** Write a new standalone script `backend/scripts/ehn-fec-finance.ts` targeted specifically to Eleanor Holmes Norton (politician UUID `4dbc8de1-9984-42a5-b2aa-5445bf0619b9`). Do NOT run the full `run-fec-finance-summary.ts` script — that processes all ~535 federal politicians, takes ~10 minutes, and risks overwriting existing data.
- **D-02:** EHN has `bioguide_id = N000147` in the DB. Use the same three-step FEC API pattern as `run-fec-finance-summary.ts`: (1) `candidates/search/?candidate_id=X` → committee_id, (2) `candidates/totals/?candidate_id=X&cycle=2026` → total_raised, (3) `schedules/schedule_a/by_employer/?committee_id=Y` → top_donors. Build the FEC candidate_id by looking her up via `bioguide_id → congress-legislators YAML` (same crosswalk as the existing script).
- **D-03:** The script writes directly to the DB via `pool.query()` with `UPDATE essentials.politicians SET finance_summary = $1::jsonb WHERE id = $2`. No migration needed — same pattern as existing FEC scripts.

### DC OCF Assessment

- **D-04:** Research-first strategy: the plan's executor first researches ocf.dc.gov to determine whether structured/machine-readable data is accessible. If a REST API or bulk download (JSON/CSV) is found → attempt ingestion. If only HTML search UI exists → write a one-paragraph documented finding and close DCFI-02.
- **D-05:** Accessibility threshold: only attempt ingestion if DC OCF exposes a REST API endpoint or a bulk export download (JSON, CSV, or similar). An HTML-only search interface does NOT qualify — document it and close DCFI-02 with the finding.
- **D-06:** If OCF data IS accessible, use the same `finance_summary` JSONB shape as FEC data: `{total_raised, top_donors, cycle, source: 'DC_OCF'}`. Fill what OCF provides; set fields to null or 0 where OCF doesn't have equivalent data. Keeps the API response shape consistent for frontend consumers.

### Plan Structure

- **D-07:** 1 plan with 2 sequential tasks: T1 = EHN FEC script, T2 = DC OCF assessment + ingestion/documentation. Small scope — no wave isolation needed.

### Claude's Discretion

- Script structure: the `ehn-fec-finance.ts` script can be minimal — hardcode EHN's politician UUID, load FEC API key from env, run the three-step FEC fetch, write the result. No need to build a general-purpose framework.
- OCF finding format: if documenting "no accessible data," a brief paragraph in the migration comment or a standalone `107-OCF-ASSESSMENT.md` file is acceptable — executor decides what's most useful.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements + Roadmap
- `.planning/REQUIREMENTS.md` — DCFI-01, DCFI-02 exact requirement text
- `.planning/ROADMAP.md` §Phase 107 — goal, success criteria, depends-on

### FEC Ingestion Scripts (reuse patterns from these)
- `backend/scripts/run-fec-finance-summary.ts` — three-step FEC API pattern (candidates/search → candidates/totals → schedules/schedule_a/by_employer), crosswalk logic (bioguide → congress-legislators YAML), rate limiting (1500ms between calls), finance_summary write pattern
- `backend/scripts/fix-fec-name-mismatches.ts` — alternate crosswalk (name-based), politician_sources lookup, same FEC API calls

### DC Politician Records
- `supabase/migrations/20260607000005_287_dc_official_records_ag_shadow_ehn.sql` — EHN's record: UUID `4dbc8de1-9984-42a5-b2aa-5445bf0619b9`, external_id = -600030, bioguide_id = 'N000147', NATIONAL_LOWER office

### Finance Schema
- `backend/src/routes/essentialsRouter.ts` — where `finance_summary` surfaces on `GET /api/essentials/politicians/:id` (confirm the field is already serialized)

### Prior Phase Context
- `.planning/phases/105-dc-infrastructure-official-records/105-CONTEXT.md` — D-12 external_id range, confirmed EHN records
- `.planning/phases/106-dc-stance-research/106-CONTEXT.md` — D-08 EHN external_id = -600030

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `backend/scripts/run-fec-finance-summary.ts` — three-step FEC fetch pattern; copy and adapt for EHN-specific script (trim to single-politician, hardcode UUID, same FEC API calls)
- `backend/src/lib/db.ts` — `pool` import for direct postgres writes

### Established Patterns
- **`pool.query('UPDATE essentials.politicians SET finance_summary = $1::jsonb WHERE id = $2', [json, uuid])`** — exact pattern used by existing FEC scripts for DB write
- **`AbortSignal.timeout(30_000)`** on all FEC API calls — don't omit
- **1500ms sleep between FEC calls** — stays under 1000 req/hr rate limit
- **Three-step FEC fetch**: `candidates/search` → committee_id, then `candidates/totals` → receipts, then `schedules/schedule_a/by_employer` → top donors by employer. Committee_id comes from `principal_committees[0].committee_id` in search response (if missing, fall back to `/v1/candidate/{id}/committees/` per FEC memory note).
- **congress-legislators YAML** at `https://raw.githubusercontent.com/unitedstates/congress-legislators/main/legislators-current.yaml` — authoritative FEC ID crosswalk source (theunitedstates.io JSON returned 410 Gone on 2026-06-04)

### Integration Points
- `essentials.politicians.finance_summary` — JSONB column already exists; script writes directly via `pool.query()`
- `GET /api/essentials/politicians/:id` — already serializes `finance_summary`; no API changes needed
- `FEC_API_KEY` env var — required, already present in backend `.env` from prior FEC work

</code_context>

<specifics>
## Specific Ideas

- **EHN politician UUID** = `4dbc8de1-9984-42a5-b2aa-5445bf0619b9` (confirmed in DB). Hardcode in the targeted script rather than querying by name.
- **EHN bioguide_id** = `N000147` — use this to look up her FEC candidate ID in the congress-legislators YAML crosswalk.
- **FEC committee_id fallback** (from project memory): if `candidates/search` returns empty `principal_committees`, fall back to `GET /v1/candidate/{id}/committees/?per_page=5` — returns all committees regardless of cycle.
- **DC OCF URL**: `ocf.dc.gov` — executor should assess this site for API/bulk download availability before attempting any ingestion.

</specifics>

<deferred>
## Deferred Ideas

- **FEC name-match queue cleanup** (from project memory): 11 sitting senators/House members have `politician_sources` rows but NULL `finance_summary` due to committee lookup failure. Fix is in `fix-fec-name-mismatches.ts`. This is separate from Phase 107 scope — belongs in a dedicated quick task or future data quality phase.
- **Finance data for Shadow Senators + SBOE**: Paul Strauss and Ankit Jain are DC-registered officials with DC OCF filings (not FEC). SBOE members may also have OCF filings. If OCF data turns out to be accessible via DCFI-02, future work could extend to these officials. Out of v2.8 scope.

</deferred>

---

*Phase: 107-DC Finance*
*Context gathered: 2026-06-08*
