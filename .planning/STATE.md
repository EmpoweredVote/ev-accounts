---
gsd_state_version: 1.0
milestone: v2026.3
milestone_name: Legislative Profile Data
status: unknown
last_updated: "2026-03-02T15:50:32.242Z"
progress:
  total_phases: 6
  completed_phases: 6
  total_plans: 15
  completed_plans: 15
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-01)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** Phase 57 — State Data Pipeline (57-01 Task 1 complete; paused at Task 2 human-action checkpoint)

## Current Position

Phase: 57 — State Data Pipeline
Plan: 01/02 (Task 1 complete, paused at Task 2 checkpoint)
Status: PAUSED — awaiting human-action: run Indiana import with credentials
Last activity: 2026-03-02 — Completed 57-01 Task 1 (state legislative import script); paused at Task 2 (install deps + run Indiana import)

```
Progress: [----------] 0/6 phases complete (5/16 plans complete)
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
- **isCurrentLeadershipRole filter is critical:** YAML leadership_roles includes full history per member (e.g., Schumer as Minority Whip 2007-2009). Without end-date filter, ~40 rows imported instead of expected ~8. (55-02)
- **LegiScan monthly counter uses atomic rename:** Write to temp file then os.Rename() — survives process crashes mid-write. Counter persists to $HOME/.ev-backend/legiscan_counter.json. (55-02)
- **Committee API endpoint uses raw SQL JOIN (not GORM chain):** Three-table join (memberships → committees LEFT JOIN parent) is cleaner as raw SQL. Pattern matches GetPoliticianEndorsements. (55-03)
- **Both Phase 55 endpoints are public (no auth):** Consistent with Phase B candidacy endpoints. Committee and leadership data is publicly available information. (55-03)
- **Congress.gov fetchPaginated stop condition is n < limit:** The API removed the total field; a page returning exactly 250 items does NOT guarantee there are more pages — only n < 250 is a reliable terminal signal. (56-01)
- **GetBillSummary lowercases billType in URL path:** Congress.gov /bill/{congress}/{type}/{number}/summaries requires lowercase bill type ("hr" not "HR"). (56-01)
- **Non-paginated CongressClient methods use limiter.Wait directly:** GetHouseVoteMemberVotes and GetBillSummary always fit in one response — they call limiter.Wait directly rather than going through fetchPaginated. (56-01)
- **Bills endpoint defaults to excluding "Introduced" status:** Significance filter reduces noise for frontend; ?all=true overrides. Calibrate after first real import. (56-04)
- **fmt.Sprintf for conditional SQL filter injection:** GetPoliticianBills uses fmt.Sprintf to conditionally add the status_label filter — named @params conflicted with %s placeholder in same query. Positional ? args used throughout. (56-04)
- **Post-upsert SELECT required for bill DB UUID:** GORM OnConflict Create does not reliably populate struct ID field for existing rows — follow-up SELECT by (external_id, jurisdiction) required after bill upsert for cosponsor linking. (56-02)
- **Cosponsored bill upsert excludes sponsor_id from DoUpdates:** The bill may already exist with correct primary sponsor from another member's sponsored-legislation list — overwriting with nil would corrupt attribution. (56-02)
- **getMasterList is a MAP not array:** LegiScan getMasterList returns `{"masterlist": {"0": {session_metadata}, "1": {bill}, ...}}` — parse as `map[string]json.RawMessage`, skip key "0". Never attempt to Unmarshal as a slice. (56-03)
- **Senator bridge via getSessionPeople name matching:** Single match only — 0 or 2+ matches are skipped. Avoids corrupting vote attribution with incorrect person linkages. Bridge rows use id_type='legiscan'. (56-03)
- **State import uses inline vote fetch per bill:** import_votes_for_bill called inside import_bills loop — avoids double getBill calls. Each bill's vote stubs drive getRollCall for member-level votes. (57-01)
- **State jurisdiction = lowercase full name:** "indiana" not "IN", "california" not "CA" — matches federal pattern in schema. (57-01)
- **Committee memberships re-fetch getSessionPeople after bill pass:** committee_db_map only populated during bill import; membership upsert needs this map, so getSessionPeople is called once more per session. (57-01)

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

Last session: 2026-03-02
Stopped at: 57-01 Task 1 complete (state legislative import script created); paused at Task 2 checkpoint (human-action: install deps + run Indiana import with LEGISCAN_API_KEY + DATABASE_URL)
Resume: After Task 2 human-action, resume 57-01 Task 2 continuation or proceed to 57-02
