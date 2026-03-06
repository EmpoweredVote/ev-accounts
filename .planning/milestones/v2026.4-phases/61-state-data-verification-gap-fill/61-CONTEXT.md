# Phase 61: State Data Verification & Gap-Fill - Context

**Gathered:** 2026-03-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Audit Indiana and California legislative data (bills, votes, committee memberships) for completeness, cross-reference against the known legislator roster in our DB, fill straightforward gaps via re-import, and document any remaining gaps with root causes. This phase covers verification and easy gap-fill only — new data sources or code changes belong in future phases.

</domain>

<decisions>
## Implementation Decisions

### Verification methodology
- Compare our DB bill/vote counts against LegiScan session totals (getDatasetList API)
- Acceptable margin: 90%+ match — up to 10% discrepancy is OK (accounts for joint resolutions, procedural votes, unmatchable records)
- Verify current session only: IN 2025-2026, CA 2025-2026
- Committee verification: accept Phase 60 results (IN 88.9%, CA 83.8% — both pass 80% threshold). Do not re-run validate_committee_coverage.py; reference Phase 60's verification report

### Gap-fill scope
- Fix what's easy, document the rest
- "Easy fix" = re-run the full LegiScan dataset import (idempotent upsert, ~5 API calls per state). Safe to re-run and catches anything missed on first pass
- Targeted patches only if re-import doesn't resolve specific gaps
- Gaps requiring new data sources or code changes get documented for future phases
- Verify the legislative_id_bridge records are complete and correct — unmatched legislators are a common data gap source

### Zero-activity legislators
- Use term start date heuristic: if term started within last 6 months of session, flag as "new — may have limited activity"
- Legislators with established terms but zero bills/votes flagged as "established — suspected gap"
- Don't blindly flag freshmen as data problems

### Audit output format
- Two deliverables: Python validation script + markdown audit report
- Validation script lives in EV-Backend/scripts/ (consistent with validate_committee_coverage.py)
- Markdown audit report lives in .planning/phases/61-*/ (phase deliverable, not codebase artifact)
- Script is re-runnable with exit code 0/1; markdown captures point-in-time findings and root causes

### Report detail level
- Aggregate stats + flagged outliers — not per-legislator detail
- Show: total bills imported, total votes imported, coverage percentages, pass/fail per state
- Individual legislators listed only if anomalous (zero activity when expected, missing bridge records)

### Cross-reference approach
- Enumerate from our DB roster (politicians with STATE_UPPER/STATE_LOWER district types for IN and CA)
- Spot-check linkage correctness: auto-select legislators by role (speaker, president pro tem, majority/minority leaders, plus a random backbencher per chamber)
- Verify specific bills/votes are correctly attributed for spot-checked legislators
- Flag orphaned records: count bills/votes in DB with no politician linkage. Report count + sample. These indicate matching failures

### Claude's Discretion
- Specific SQL queries and script structure
- Which LegiScan API calls to use for session total comparison
- Term start date threshold for "new legislator" heuristic
- Auto-selection algorithm for spot-check legislators
- How to identify orphaned bill/vote records efficiently
- Whether to extend existing validate_committee_coverage.py or create a new script

</decisions>

<specifics>
## Specific Ideas

- validate_committee_coverage.py is the pattern to follow — same .env.local, same psycopg2 approach, same --dry-run/--verbose flags, same exit code convention
- LegiScan dataset import (import_state_legislative.py) is idempotent — safe to re-run as gap-fill strategy
- Phase 60 accumulated context: IN has 61 memberships (88.9% coverage), CA has 213 memberships (83.8% coverage) — both already validated
- LegiScan budget tracking in ~/.ev-backend/legiscan_counter.json — monitor API usage during re-import

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `EV-Backend/scripts/validate_committee_coverage.py`: Pattern for validation scripts — DB connection, threshold checks, spot-checks, exit codes. Can be referenced for the new bills/votes validation script.
- `EV-Backend/scripts/import_state_legislative.py`: LegiScan dataset importer with session configs, nickname matching, budget tracking. The gap-fill tool — re-running this is the primary fix strategy.
- `EV-Backend/scripts/import_state_committees.py`: Committee import with IGA + Open States clients. Already validated in Phase 60.
- `EV-Backend/internal/essentials/legiscan_client.go`: Go LegiScan client — not directly used here (Python scripts handle imports) but defines the data model.

### Established Patterns
- Python scripts in EV-Backend/scripts/ with --dry-run, --verbose, --state flags
- .env.local for DATABASE_URL and API keys (LEGISCAN_API_KEY)
- Nickname mapping (NICKNAME_GROUPS) for fuzzy legislator matching
- Budget tracking in ~/.ev-backend/ JSON files
- Validation scripts exit 0 (pass) or 1 (fail) for CI-style usage

### Integration Points
- `essentials.legislative_id_bridge` — maps LegiScan/Open States IDs to our politician UUIDs. Key table for cross-reference verification.
- `essentials.bills`, `essentials.bill_cosponsors`, `essentials.votes` — the tables being audited
- `essentials.legislative_committee_memberships` — already validated in Phase 60
- `essentials.legislative_sessions` — session records for IN/CA should exist from v2026.3 import

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 61-state-data-verification-gap-fill*
*Context gathered: 2026-03-05*
