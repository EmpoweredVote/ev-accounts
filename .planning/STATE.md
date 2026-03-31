---
gsd_state_version: 1.0
milestone: v2026.3.8
milestone_name: Essentials Election Central
status: executing
stopped_at: Completed 101-01-PLAN.md
last_updated: "2026-03-31T02:07:29.380Z"
last_activity: 2026-03-31 - Completed quick task 260330-uph: Remove NavSearch bar and Show Candidates toggle
progress:
  total_phases: 10
  completed_phases: 10
  total_plans: 22
  completed_plans: 22
  percent: 95
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-29)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** Phase 101 — candidate-profiles

## Current Position

Phase: 101
Plan: Not started
Status: Wave 2 in progress — 101-01 complete
Last activity: 2026-03-31

Progress: [██████████] 95%

## Performance Metrics

**Velocity (v2026.3.7):** 5 phases, 11 plans
**Velocity (v2026.3.6):** 7 phases, 15 plans, 3 days
**Velocity (v2026.3.5):** 3 phases, 5 plans, 1 day

*Updated after each plan completion*

## Accumulated Context

### Decisions

- [Roadmap]: CivicEngine API access status must be confirmed before any import script work begins in Phase 97 — if unavailable, fallback is Google Civic API + manual staging with documented Monroe County local race gaps
- [Roadmap]: Candidates stored in essentials.race_candidates (separate table), NOT in essentials.politicians — prevents geofence searches from returning candidates mixed with officials
- [Roadmap]: faces_retention_vote boolean added to essentials.politicians in Phase 97 to model Indiana retention judges before filter UI ships in Phase 100
- [Roadmap]: Party affiliation excluded at the schema/ingestion layer with antipartisan rationale comments — never stored even if upstream APIs provide it
- [Phase 97]: Phase 100 filter must check politician.is_appointed first (individual override), then fall back to offices.is_appointed_position — handles Courtney Daily interim-appointment-to-elected-seat edge case
- [Phase 97]: Phase 100 filter is not blocked by is_appointed data quality: geofence join excludes campaign finance records, Bloomington demo data is well-classified, and Judge offices are the only P1 backfill item
- [Phase 97-schema-foundation-data-audit]: Indiana SoS Excel actual columns differ from research: OFFICE, CANDIDATE NAME, POLITICAL PARTY, DISTRICT, DATE FILED (no Last Name or Incumbent) — is_incumbent must be determined by politician_id matching at Phase 98 import time
- [Phase 98-election-data-import]: Indiana district filter requires both DISTRICT and OFFICE column check to exclude convention delegate races from other counties
- [Phase 98-election-data-import]: State Senate District 40 absent from 2026 primary (staggered 4-year terms) — correct behavior, not a data gap
- [Phase 98-02]: Two-part election query: Part A geofence-matched races (office_id linked), Part B statewide fallback (office_id IS NULL, matched by state code from geofence) — all current imported races use Part B since office_id not yet linked
- [Phase 98-02]: upsertRace requires explicit SELECT-then-INSERT/UPDATE branch for NULL primary_party (PostgreSQL ON CONFLICT can't handle partial index NULLs-distinct behavior)
- [Phase 99]: ADDRESS_NOT_FOUND and PO_BOX_REJECTED return 200 { elections: [] } for elections-by-address — consistent with 'no elections found' rather than a user error
- [Phase 99]: Primary elections show party ballot labels — antipartisan exception because voters must choose a party ballot
- [Phase 99]: Local candidate data deferred — Indiana SoS only covers state/federal; Monroe County Clerk data needed for local races
- [Phase 99]: inferDistrictType parses position_name for accurate district_type when office_id not yet linked
- [Phase 99]: ev:fromView sessionStorage pattern for tab-aware back navigation between Elections/Representatives
- [Phase 100-01]: essentialsBrowseService.ts also implements PoliticianFlatRecord — auto-fixed to include is_appointed and faces_retention_vote alongside essentialsService.ts
- [Phase 100]: resolveIsAppointed checks politician.is_appointed first (individual override), falls back to !is_elected — handles retention judge dual-appearance in both Elected and Appointed filter views
- [Phase 101]: UUID_RE moved to top of essentials.ts (after router declaration) so all route handlers can reference it without forward-reference issue
- [Phase 101]: CandidateDetail includes election_date and election_type for frontend context display without a second fetch

### Pending Todos

- 12 politicians have no Read & Rank quotes (carried from v1.8)

### Blockers/Concerns

- Phase 97: CivicEngine API access unconfirmed — could require contract; Google Civic has unconfirmed Monroe County IN local race coverage
- Phase 97: is_appointed data quality for post-v1.5 officials unknown until audit query runs; if predominantly defaulted false, Phase 100 is blocked until manual backfill completes
- Phase 98: Data rot risk — candidate_status field and last_verified_at needed in schema before any data is entered

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260330-uph | Remove NavSearch bar and Show Candidates toggle from essentials | 2026-03-31 | eaf8638 | [260330-uph-remove-navsearch-bar-and-show-candidates](./quick/260330-uph-remove-navsearch-bar-and-show-candidates/) |

## Session Continuity

Last session: 2026-03-30T20:39:06.392Z
Stopped at: Completed 101-01-PLAN.md
Resume file: None
