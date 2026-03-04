---
gsd_state_version: 1.0
milestone: v2026.3
milestone_name: Legislative Profile Data
status: unknown
last_updated: "2026-03-03T18:40:14.159Z"
progress:
  total_phases: 9
  completed_phases: 8
  total_plans: 24
  completed_plans: 23
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-01)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** Phase 58 — Local Data Pipeline (58-01 feasibility check complete; ready for 58-02 Bloomington import and 58-03 LA County import)

## Current Position

Phase: 59 — Frontend Profile Sections
Plan: 04/04 complete
Status: COMPLETE — phase 59 fully done; all 4 plans executed (01 ev-ui components, 02 essentials wiring, 03 gap closure plans created, 04 gaps 4+5 diagnosed as data pipeline issues)
Last activity: 2026-03-03 — Completed 59-04 (federal and local data gaps diagnosed as import CLI commands not run; no code changes needed)

```
Progress: [----------] 0/6 phases complete (6/16 plans complete)
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
- **LegislativeInlineSummary returns null for empty data:** Local politicians with no legislative data see the unchanged profile — guard is on both recent_bills and recent_votes being empty. (59-01)
- **Year extraction uses slice(0,4) not new Date():** Avoids timezone bug where "2024" parsed as UTC midnight Jan 1 shows "Dec 2023" in US timezones. Pattern applies to all date-derived year dropdowns in ev-ui. (59-01)
- **LegislativeRecord is a headless content component:** No routing, no Header, no data fetching — page wrapper in essentials handles those concerns. Keeps ev-ui components portable. (59-01)
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
- **Local scope confirmed = committees and legislation only:** Live probes confirm vote attribution infeasible — Legistar /VoteRecords returns 404, OnBoard has no vote data at all. (58-01)
- **LA County plan 58-03 scoped to OfficeRecords only:** MatterRequester NULL for 98% of recent BOS matters; MoverName only populated pre-2010. No recent legislation attribution possible. (58-01)
- **Bloomington sponsor extraction best-effort (~50% coverage):** Regex confirmed working on live pages (3/3 sampled). Import where sponsor text found; skip+log where absent. (58-01)
- **Barger and Mitchell return AMBIG name matches:** ILIKE returns multiple DB rows for these supervisors. Plan 58-03 must use Legistar PersonId as primary bridge key — do not rely on name matching alone. (58-01)
- **Courtney Daily missing from DB:** No record in essentials.politicians for this Bloomington council member. Investigate BallotReady cache freshness for ZIP 47401/47403 before 58-02 import. (58-01)
- **Legislative fetch functions silently return empty defaults on error:** Profile page always renders even if legislative API is unavailable — guard pattern established in api.jsx. (59-02)
- **bills and votes fetched with limit=200:** Supports year filter and show-all without extra API calls — ev-ui component caps display internally at 25 items. (59-02)
- **Flat sibling route /politician/:id/record:** Profile.jsx has no Outlet; LegislativeRecordPage is a standalone page shell with its own Header and data fetching. (59-02)
- **onNavigateToRecord callback keeps ev-ui portable:** No react-router import in component library — SPA-specific navigation passed as callback prop; falls back to window.location.href for non-SPA contexts. (59-03)
- **navigate('/') for Profile back button:** Deterministic dashboard route prevents Profile<->Record navigation loop; navigate(-1) was unsafe given bi-directional navigation between these pages. (59-03)
- **Gap 4 and Gap 5 confirmed as data pipeline issues, not code bugs:** Federal officials return empty legislative data because `backfill-legislative-ids` + import CLIs have not been run on the active database. Local politicians return no committee data because local import scripts have not been run. Shelli Yoder state data working confirms schema, endpoints, and queries are all correct. LA County BOS committee absence is a permanent Legistar limitation (endpoint does not exist). No Phase 59 code changes needed. (59-04)
- **LegiScan getSessionPeople does not provide per-legislator committee membership:** Returns committee_id=0 for all legislators; the ~34 CA entries with non-zero committee_id are committee metadata stubs (empty names), not legislator-committee links. State legislative_committee_memberships table is empty for IN and CA. /committees endpoint returns [] for state legislators. Committees table (from bill referrals) is populated correctly: 41 IN, 60 CA. (57-02)
- **Open States committee matching uses two-pass strategy:** Name lookup first against existing 41 IN / 60 CA committees (from LegiScan bill referrals), then creates new rows with source='openstates' where unmatched — avoids duplicating existing data. Open States jurisdiction param uses state names ("Indiana", "California") not abbreviations. (57-03)
- **Single-match-only guard for Open States politician name resolution:** 0 or 2+ name matches → log at DEBUG → skip. ILIKE first_name prefix handles middle initials. Bridge rows created with id_type='openstates' for OCD person IDs to speed future re-runs. congress_number=0 for all state legislators. (57-03)

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
- **Bloomington OnBoard REST API:** CONFIRMED — HTML scraping works. Committee pages accessible (IDs 1, 77, 81, 49), legislation listing accessible, sponsor regex extraction working. No REST API exists but HTML scraping is sufficient.
- **LA County Legistar token requirement:** CONFIRMED RESOLVED — /VoteRecords returns 404 (no token gating issue, endpoint simply doesn't exist). OfficeRecords and Matters endpoints are open.
- **Significance filter calibration:** After first federal bill import, check what percentage are "introduced" status only. Calibrate default filter cutoff from actual data distribution before building the UI filter.
- **Courtney Daily missing from DB:** Bloomington council member not found in essentials.politicians. May require BallotReady re-fetch for ZIP 47401/47403. Document as known gap for 58-02.

## Session Continuity

Last session: 2026-03-04
Stopped at: 57-03-PLAN.md Task 2 checkpoint:human-action — import_state_committees.py created (Task 1 done, 0abc68f); awaiting OPENSTATES_API_KEY setup and manual import run for IN + CA
Resume: After adding OPENSTATES_API_KEY to EV-Backend/.env.local and running `python import_state_committees.py --state IN --verbose` then `--state CA`, type "approved" to continue to SUMMARY finalization
