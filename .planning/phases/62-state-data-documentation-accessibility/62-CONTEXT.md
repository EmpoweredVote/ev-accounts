# Phase 62: State Data Documentation & Accessibility - Context

**Gathered:** 2026-03-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Document repeatable import scripts for Indiana and California state legislative data, and confirm all imported data is accessible through existing API endpoints. This phase covers documentation and verification only — no new import functionality or API endpoints.

</domain>

<decisions>
## Implementation Decisions

### Documentation format
- Expand existing EV-Backend/scripts/README.md with a new "State Legislative Imports" section
- Two major sections: Section 1 (Geofence Imports — existing), Section 2 (State Legislative Imports — new)
- Shared prerequisites section at top covering Python version, pip install, DATABASE_URL
- Each major section lists its additional env vars (e.g., LEGISCAN_API_KEY, OPENSTATES_API_KEY for state legislative)
- Document both requirements files: requirements.txt for geofence, requirements-state.txt for state legislative

### New-session playbook
- Inline numbered checklist in the State Legislative section for re-running imports when a new session starts
- Checklist includes: update config, run imports, run validation, verify API responses
- Extract session configs from both import_state_legislative.py and import_state_committees.py into a shared JSON config file
- Config file: state_legislative_config.json in EV-Backend/scripts/ (consistent with pipeline_config.json and legiscan_counter.json patterns)
- Both import scripts read session definitions from this single config file — one place to update for new sessions

### API verification approach
- New Python verification script that hits the Go API server (not just DB queries)
- Tests the full stack: endpoints, GORM queries, JSON serialization
- Accepts --api-url flag with default http://localhost:5050
- For known IN and CA legislators: confirms 200 response, non-empty JSON arrays, expected fields (committee name, bill title, vote result)
- Checks all 4 legislative endpoints: /committees, /bills, /votes, /legislative-summary
- Non-empty + structure check — no strict count thresholds (data changes each session)

### Documentation depth
- Runbook-style: step-by-step with expected output examples at each step
- A developer who has never touched these scripts can follow it start to finish
- Includes troubleshooting section for known gotchas: Supabase idle connection timeout (~15 min CA imports), LegiScan API budget limits, Open States rate limiting, 403 errors
- Validation scripts (validate_committee_coverage.py, validate_state_legislative.py) documented as verification steps in the import workflow
- No expected data count tables — counts are session-specific and would be misleading for future sessions

### Claude's Discretion
- Exact JSON config schema for state_legislative_config.json
- How to refactor import scripts to read from external config (minimal changes preferred)
- API verification script structure and specific test legislator IDs
- Troubleshooting section content based on known issues from Phase 60/61
- README section ordering and heading hierarchy

</decisions>

<specifics>
## Specific Ideas

- Follow existing patterns: pipeline_config.json and legiscan_counter.json already use JSON configs in scripts/
- Supabase idle connection timeout is a real gotcha — CA committee import takes ~15 min of API pagination, and the DB connection drops if not handled (fixed in Phase 60 with reconnect logic)
- Phase 61 audit report has the definitive data: IN 935 bills/6,069 votes PASS, CA 4,746 bills/92,492 votes PASS — reference this as the baseline validation

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `EV-Backend/scripts/README.md`: Existing geofence import docs — will be expanded with state legislative section
- `EV-Backend/scripts/import_state_committees.py`: Has inline SESSION_CONFIGS dict to extract to external JSON
- `EV-Backend/scripts/import_state_legislative.py`: Has inline SESSION_CONFIGS dict to extract to external JSON
- `EV-Backend/scripts/validate_committee_coverage.py`: Validation pattern — DB connection, threshold checks, exit codes
- `EV-Backend/scripts/validate_state_legislative.py`: Full legislative validation script — bills, votes, bridge records
- `EV-Backend/scripts/utils.py`: Shared utilities (load_env, get_engine) — new scripts should use these

### Established Patterns
- Python scripts with --dry-run, --verbose, --state flags
- .env.local for DATABASE_URL and API keys
- JSON config files in scripts/ (pipeline_config.json, legiscan_counter.json)
- Validation scripts exit 0 (pass) or 1 (fail)
- requirements.txt and requirements-state.txt for separate dependency sets

### Integration Points
- Go API server on localhost:5050 — verification script hits /essentials/politician/{id}/committees, /bills, /votes, /legislative-summary
- essentials.legislative_sessions — session records for IN/CA
- essentials.legislative_id_bridge — links external IDs to politician UUIDs
- ~/.ev-backend/ — tracker files for budget monitoring

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 62-state-data-documentation-accessibility*
*Context gathered: 2026-03-05*
