# Phase 60: Indiana & California Committee Import - Context

**Gathered:** 2026-03-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Import current committee memberships for Indiana and California state legislators into the database from authoritative APIs. Data must surface on Essentials legislator profile pages. This phase covers import only — verification and gap-fill are Phase 61.

</domain>

<decisions>
## Implementation Decisions

### CA Data Source
- Explore direct CA legislature API (leginfo.legislature.ca.gov) first — prefer no-auth, no-rate-limit like IGA
- Fall back to Open States API v3 (free tier, 6-second delays, ~10 min total) if direct API unavailable or too complex
- Do not pursue paid Open States tier — free is acceptable for one-time imports
- Standing committees only for both states — match Indiana's existing filter (no subcommittees, no conference committees)

### Session Scope
- Current session only: 2026 for Indiana, 2025-2026 for California
- Previous session can be added in Phase 61 if needed
- Tag all committee memberships with session_id for future session filtering

### Target Schema
- Write to v2026.3 `legislative_committees` and `legislative_memberships` tables (not the older `committees`/`politician_committees` tables)
- Migrate any existing state committee data from old tables to legislative_committees
- Consistent with federal committee data already stored in v2026.3 schema

### Data Freshness
- Upsert strategy on re-run — safe to re-run anytime, overwrites with fresh API data
- Log last-run timestamp to `~/.ev-backend/committee_import_tracker.json` (matching LegiScan tracker pattern)
- Print summary report at end: committees imported, memberships created, match failures
- Unmatched legislators: log warning and skip — do not create stub politician records

### Validation
- Two-pronged: automated validation script + quick manual browse
- Coverage threshold: 80%+ of legislators per state should have at least one committee assignment
- Spot-check: Claude picks a mix of leadership and rank-and-file from both chambers per state
- Automated script queries DB for coverage percentages and specific legislator checks
- Manual confirmation: eyeball 2-3 profiles in Essentials browser

### Claude's Discretion
- IGA API endpoint specifics and session parameter format
- CA legislature API research and client implementation
- Legislator name-matching algorithm (existing nickname mapping can be extended)
- Old table migration strategy (SQL script vs Python migration)
- Validation script structure and specific test legislators

</decisions>

<specifics>
## Specific Ideas

- IGA API (iga.in.gov/api) already works with no auth and no rate limits — discovered at end of v2026.3 Phase 57
- import_state_committees.py already has working IGA client code — needs retargeting from old tables to legislative_committees
- Open States rate limiting is handled with 6-second delays in existing code

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `EV-Backend/scripts/import_state_committees.py`: Full IGA + Open States client with name matching, role normalization. Needs retargeting to v2026.3 tables.
- `EV-Backend/scripts/import_state_legislative.py`: LegiScan dataset importer with session configs, nickname matching, budget tracking. Pattern reference.
- `EV-Backend/internal/essentials/models.go`: LegislativeCommittee, LegislativeMembership, LegislativeSession models already defined.
- `~/.ev-backend/legiscan_counter.json`: Budget tracker pattern to replicate for committee import tracking.

### Established Patterns
- Python import scripts in `EV-Backend/scripts/` with `--dry-run`, `--verbose`, `--state` flags
- `.env.local` for DATABASE_URL and API keys
- Nickname mapping (NICKNAME_GROUPS) for fuzzy legislator matching
- Role normalization dictionaries for chair/vice_chair/member

### Integration Points
- legislative_committees table (v2026.3 schema) — already read by GET /essentials/committees endpoint
- legislative_memberships table — already read by frontend LegislativeInlineSummary component
- legislative_sessions table — session records for IN/CA may need creating if not present
- Essentials profile pages — committee section already renders from legislative_memberships

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 60-indiana-california-committee-import*
*Context gathered: 2026-03-05*
