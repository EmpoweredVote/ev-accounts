---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: completed
stopped_at: Completed 76-frontend-results-integration-01-PLAN.md
last_updated: "2026-03-11T00:00:00.000Z"
last_activity: 2026-03-11 — Phase 76-01 complete; splitByBodyName helper added to Results.jsx; backend SearchPoliticians endpoint fixed with government_bodies LEFT JOIN; all BODY-01 through BODY-05 requirements verified
progress:
  total_phases: 6
  completed_phases: 6
  total_plans: 6
  completed_plans: 6
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-10)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** v2026.3.3 Local Government Organization — Phase 72: DB Audit

## Current Position

Phase: 76 of 76 (Frontend Results Integration)
Plan: 1 of 1 complete
Status: Phase 76 complete — all phases done
Last activity: 2026-03-11 — Phase 76-01 complete; splitByBodyName helper added to Results.jsx; backend SearchPoliticians endpoint fixed with government_bodies LEFT JOIN; all BODY-01 through BODY-05 requirements verified

Progress: [██████████] 100%

## Performance Metrics

**Velocity (v2026.3.2):** 5 phases, 8 plans
**Velocity (v2026.4):** 7 phases, 24 plans
**Velocity (v2026.3):** 6 phases, 19 plans

*Updated after each plan completion*

## Accumulated Context

### Key Decisions for This Milestone

- Phase 72 (DB audit) gates all classification code — must confirm chamber_name_formal values before writing any body_key logic
- GovernmentBody table uses composite unique (state, geo_id, body_key) — upsert-safe, follows PositionDescription enrichment pattern
- body_key derived by classify.go (Go mirror of classify.js) — ensures JOIN keys match frontend classification
- Phase 75 (ev-ui) can run in parallel with Phases 73-74 — no backend dependency for the prop addition
- Use government_body_name from API directly for section headers — never pass through qualifyLocalTitle() (causes double-prefix)
- classify.js LOCAL_ORDER, CATEGORY_DISPLAY_NAMES, GROUP_SORT_OPTIONS must always update atomically in the same commit
- **[72-01] Phase 73 is a DATA MIGRATION phase** — chamber_name_formal is empty for all Indiana officials; must populate canonical body names before GovernmentBody body_key logic can work
- **[72-01] Monroe County Commissioners misclassified as County Officials** — "commission" substring not matched by hasAny("commissioner"); Phase 73 must add "commission" to classify.js COUNTY branch keyword list
- **[72-01] No collision between Commission and Council** — Council → County Legislators (via "council" match), Commission → County Officials (fallback); original collision concern was wrong about mechanism
- **[72-01] Monroe County G4020 geofence present** — geo_id=18105, census_tiger_2024, imported 2026-02-11; no geofence import step needed in Phase 73
- **[73-01] GovernmentBody body_key = COALESCE(NULLIF(c.name_formal, ''), c.name, '')** — chamber name_formal takes precedence; after migration Indiana chambers use canonical names as join keys
- **[73-01] chamber_name_formal migration scoped with LIKE prefix patterns** — 'Monroe County Council%' prevents false matches in other states
- **[73-01] government_body_name/url use omitempty** — officials without matching government_bodies row return clean JSON, empty string suppressed
- **[74-01] Individual county offices share body_key='Monroe County Government'** — name_formal UPDATE in setup.go groups Sheriff, Assessor, Auditor, Coroner, Treasurer, Recorder, Surveyor, Circuit Court Clerk, Prosecuting Attorney under one government_bodies row
- **[74-01] ON CONFLICT DO NOTHING for government_bodies seed** — preserves manually-corrected URLs in production DB; DO UPDATE would overwrite on every server restart
- **[74-01] geo_id fan-out required for multi-district bodies** — Monroe County Council needs 5 rows (at-large + 4 districts), Bloomington Common Council needs 7 rows (at-large + 6 districts); one row per distinct geo_id in districts table
- **[74-01] FIPS '18' not ISO 'IN' for state column** — districts table stores FIPS codes; JOIN `gb.state = d.state` requires matching format
- **[75-01] websiteUrl placed after infoTooltip in header flex row** — order: [titlePill] [infoButton?] [linkIcon?]; || undefined guard on polList[0]?.government_body_url prevents empty string broken icons
- **[75-01] ev-ui 0.1.41 published to GitHub Package Registry** — CategorySection backward-compatible; callers without websiteUrl see zero visual change
- **[76-01] splitByBodyName is a render-time helper, not in useMemo** — placed above Results component as standalone function; sub-groups polList alphabetically by government_body_name at JSX render time only
- **[76-01] SearchPoliticians endpoint lacked government_bodies LEFT JOIN** — FindPoliticiansByGeoMatches had the join (Phase 73) but SearchPoliticians in geofence_lookup.go did not; fixed as Rule 3 deviation
- **[76-01] government_body_name used directly as section title** — never routed through qualifyLocalTitle() to prevent double-prefix bug; unnamed politicians fall back to getDisplayName(category)

### Tech Debt Carried Forward (from v2026.3.2)

- Dead `ballotready/` package preserved for historical reference (from v1.5)
- Orphaned `checkCacheStatus` in essentials `api.jsx` (from v1.5)
- 5 district-election cities treated as at-large (from v1.6)
- `fetchPoliticiansOnce` and `fetchPoliticiansProgressive` deprecated but not deleted in essentials `api.jsx` (from v1.9)
- `leg_data_fetched_at` column unused (from v2026.3)
- Topic tags placeholder div in LegislativeInlineSummary (from v2026.3)

### Pending Todos

- 12 politicians have no Read & Rank quotes (carried from v1.8)
- Future: Census ZCTA-to-Place ZIP mapping for city council politicians

### Blockers/Concerns

- [RESOLVED by 72-01] Phase 72 critical branch: chamber_name_formal IS unpopulated for all Indiana chambers → Phase 73 IS a data migration phase (populate canonical body names) then feature phase

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 5 | Candidate profile system with compass stances and show-candidates filter | 2026-03-08 | 2657f3d | [5-create-candidate-profile-system-with-com](./quick/5-create-candidate-profile-system-with-com/) |
| 6 | Column-per-category contact info layout in PoliticianProfile | 2026-03-08 | 1b91b91 | [6-improve-contact-info-section-on-profile-](./quick/6-improve-contact-info-section-on-profile-/) |
| Phase 72-db-audit P01 | 4 | 2 tasks | 1 files |
| Phase 73-backend-governmentbody-table P02 | 5 | 1 tasks | 1 files |
| Phase 74-data-seeding P01 | 2 | 1 tasks | 1 files |
| Phase 75-ev-ui-categorysection-update P01 | 3 | 2 tasks | 4 files |
| Phase 76-frontend-results-integration P01 | ~45min | 2 tasks | 2 files |

## Session Continuity

Last session: 2026-03-11T00:00:00.000Z
Stopped at: Completed 76-frontend-results-integration-01-PLAN.md
Resume: All phases complete.
