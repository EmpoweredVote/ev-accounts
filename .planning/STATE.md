---
gsd_state_version: 1.0
milestone: v2026.3
milestone_name: Legislative Profile Data
status: unknown
last_updated: "2026-03-01T00:00:00.000Z"
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 8
  completed_plans: 9
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-01)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** Phase 55 — Federal Committees & Leadership (55-01 complete)

## Current Position

Phase: 55 — Federal Committees & Leadership
Plan: 01/03 complete
Status: Phase 55 in progress — plan 01 done
Last activity: 2026-03-01 — Completed 55-01 (committee YAML import CLI)

```
Progress: [----------] 0/6 phases complete (2/16 plans complete)
```

## Performance Metrics

**Velocity (v1.9):** 3 phases, 6 plans
**Velocity (v1.8):** 6 phases, 28 plans
**Velocity (v1.7):** 6 phases, 15 plans, 36 tasks (1 plan deferred)
**Velocity (v1.6):** 7 phases, 11 plans, 23 tasks
**Velocity (v1.5):** 6 phases, 13 plans, 25 tasks

## Accumulated Context

### Key Architectural Decisions

- **Federal votes = batch import, not lazy-fetch.** A two-term senator has 8,000-12,000 roll calls. Lazy-fetch goroutines would time out Render's 30-second limit. CLI batch job mandatory before any profile-serving code written for votes.
- **Schema from data inventory, not aspirational model.** Local bodies may have no machine-readable vote data. Build tables only after confirming data exists (Phase 58 feasibility check gates commit).
- **ID bridge table before any import.** `legislative_politician_id_map` must be populated with bioguide, legiscan, legistar, and OCD-IDs before any import CLI runs. Orphaned imports are silent and unrecoverable.
- **Congress.gov pagination stop condition.** Always use `len(items) < limit` — the API silently truncates at 250 and removed the `total` field. Never assume a round number means complete.
- **YAML library.** Use `github.com/goccy/go-yaml v1.18.0` for congress-legislators YAML parsing. `gopkg.in/yaml.v3` is archived and must not be used.
- **LegiScan as state primary.** Open States is verification layer only — uneven scraper quality and outage risk. LegiScan (30K req/month free) covers IN and CA.
- **Senate votes via LegiScan.** Congress.gov API v3 does NOT include Senate roll calls as of March 2026. LegiScan covers US Congress including Senate.
- **Local scope = committees and legislation only.** No individual vote attribution for Bloomington or LA County BOS — confirmed infeasible from structured sources.
- **All legislative data stays in `internal/essentials/` package** with `legislative_` prefix tables in the `essentials` schema. No new Go package or schema.
- **Frontend implementation details TBD during phase planning.** User wants to discuss UI design more during plan-phase; requirements are set but component structure is open.
- **Tiered matching for bioguide backfill:** Tier 1 exact ID, Tier 2 name+state (single match only), skip ambiguous — no medium-confidence bridge inserts to prevent bad data. (54-02)
- **data-model.md confirmed no schema changes needed:** All 5 jurisdictions (Federal, Indiana, California, Bloomington IN, LA County CA) fit existing 8-table schema; empty tables are acceptable. (54-02)
- **Committee upserts use FirstOrCreate+Assign pattern** (not clause.OnConflict+Returning) to correctly handle GORM UUID PK generation — Returning clause doesn't populate struct fields when using OnConflict. (55-01)
- **Membership upserts use clause.OnConflict** on (committee_id, politician_id, congress_number) with DoUpdates for role/is_current/session_id — direct create path is safe since bridge table lookup guarantees politician_id exists. (55-01)

### Pending Todos

- **Future phase idea: Census ZCTA-to-Place ZIP mapping for city council politicians**
- **PHOTO-03 headshot coverage at 21.5%** — headshot_research_manifest.csv exists for future manual sprint (carried from v1.7)
- **12 politicians have no Read & Rank quotes** (carried from v1.8)
- **Validate scraper-legistar maintenance status** before Phase 58 — check last commit date on `opencivicdata/python-legistar-scraper`

### Tech Debt Carried Forward

- Dead `ballotready/` package preserved for historical reference (from v1.5)
- Orphaned `checkCacheStatus` in essentials `api.jsx` (from v1.5)
- 5 district-election cities treated as at-large (from v1.6)
- `fetchPoliticiansOnce` and `fetchPoliticiansProgressive` deprecated but not deleted in essentials `api.jsx` (from v1.9)

### Blockers/Concerns

- **Congress.gov API reliability:** Confirmed outage January 2026. Import CLI must log failures and never block profile rendering. Validate token bucket implementation with real API calls before scheduling full session import.
- **Bloomington OnBoard REST API:** Endpoints not confirmed. Requires direct validation against `data.bloomington.in.gov` before Phase 58 scraper design. Fallback: HTML scraping (but individual vote data unavailable regardless).
- **LA County Legistar token requirement:** Manually test `webapi.legistar.com/v1/LACounty/VoteRecords` with curl before Phase 58. Token gating may limit to matter-level data only.
- **Significance filter calibration:** After first federal bill import, check what percentage are "introduced" status only. Calibrate default filter cutoff from actual data distribution before building the UI filter.

## Session Continuity

Last session: 2026-03-01
Stopped at: Completed 55-01-PLAN.md — committee YAML import CLI (ImportCommittees function + main.go subcommand)
Resume: `/gsd:execute-phase 55` (Phase 55 in progress — plans 02 and 03 remaining)
