# Phase 58: Local Data Pipeline - Context

**Gathered:** 2026-03-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Import Bloomington Common Council and LA County Board of Supervisors committee assignments and legislation metadata. Feasibility-gated: a written feasibility check with manual curl/API test results must be completed and reviewed before any import work begins. No individual vote attribution — confirmed infeasible from structured sources.

</domain>

<decisions>
## Implementation Decisions

### Feasibility gate
- Plan 58-01 produces a feasibility document covering both Bloomington and LA County data sources
- Work pauses after 58-01 for user review before proceeding to import plans
- Feasibility doc includes manual curl test results for Legistar VoteRecords endpoint and Bloomington OnBoard REST API, plus website inspection findings
- Import plans (58-02, 58-03) are scoped by what 58-01 actually discovers — no assumptions about data availability

### Fallback strategy when APIs are restricted
- Invest time finding alternative approaches when primary data sources are inaccessible
- Scraping HTML pages, parsing PDFs, and other creative approaches are acceptable
- Only fall back to manual entry if automation is truly a dead end
- Manual entry is acceptable for small datasets (e.g., ~9 Bloomington council members) but automate first
- For each body, document all explored approaches and why they did or didn't work

### Legislation metadata scope
- Only import legislation that can be tied to a specific politician
- Valid ties: sponsorship, co-sponsorship, authorship, named committee referral participant, vote record
- Skip orphaned legislation with no politician attribution — document the gap instead
- For LA County Legistar: capture matters, motions, ordinances — but only where a politician is identifiable as mover/sponsor/author
- For Bloomington: if city clerk database has ordinances without sponsor/author attribution, document that gap rather than importing

### Politician matching
- Bloomington Common Council members already exist in `essentials.politicians` (from BallotReady)
- LA County BOS members already exist in `essentials.politicians` (from gap-fill scripts)
- Name matching via ID bridge table (`legislative_politician_id_map`) — single-match-only, skip ambiguous
- Feasibility check should verify both sets of politicians are findable by name before import work begins

### Claude's Discretion
- Gap documentation format — whatever makes Phase 59 frontend implementation cleanest (likely a coverage matrix or jurisdiction-capabilities lookup)
- Specific scraping/parsing approach for each data source (based on feasibility findings)
- Whether to use Legistar client library vs raw HTTP calls
- Script structure (one script per body vs combined with --body flag)
- Error handling and retry strategy for web scraping

</decisions>

<specifics>
## Specific Ideas

- The user has no prior knowledge of what these data sources contain — genuine discovery is needed during feasibility
- Feasibility should test Bloomington OnBoard REST API at data.bloomington.in.gov
- Feasibility should test LA County Legistar at webapi.legistar.com/v1/LACounty/
- STATE.md notes: validate scraper-legistar maintenance status (check last commit on opencivicdata/python-legistar-scraper) before Phase 58

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `EV-Backend/scripts/import_state_legislative.py`: Python import script pattern from Phase 57 — psycopg2 + requests, same virtual environment
- `EV-Backend/internal/essentials/models.go`: All legislative table models already exist (LegislativeCommittee, LegislativeCommitteeMembership, LegislativeBill, etc.)
- `legislative_politician_id_map` bridge table: supports `id_type='legistar'` already defined in model
- LegiScan client (`legiscan_client.go`): may be useful if LA County Legistar uses similar API patterns (it doesn't — Legistar is a different product from LegiScan)
- Python venv at `EV-Backend/scripts/.venv` with psycopg2-binary, requests, python-dotenv already installed

### Established Patterns
- Python batch import scripts write directly to PostgreSQL via psycopg2 (not through Go backend)
- UUID generation via PostgreSQL `gen_random_uuid()` in INSERT statements
- Jurisdiction strings: `"bloomington-in"` and `"la-county-ca"` (from STATE.md — verify in handlers.go during planning)
- Single-match-only name matching for bridge table — no medium-confidence inserts

### Integration Points
- Existing API endpoints from Phase 56 already serve committee/bill/vote data filtered by jurisdiction — no new endpoints needed
- Phase 59 frontend will consume these same endpoints — gap documentation format should inform what Phase 59 shows/hides per jurisdiction
- `leg_data_fetched_at` timestamp on politicians table — may need updating after local imports

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 58-local-data-pipeline*
*Context gathered: 2026-03-02*
