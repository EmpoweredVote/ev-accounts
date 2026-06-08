---
gsd_state_version: 1.0
milestone: v2.9
milestone_name: LA County Expansion
status: In progress — Phase 108 context captured
last_updated: "2026-06-08"
last_activity: 2026-06-08 — Phase 108 context captured; ready to plan
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 6
  completed_plans: 6
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-07 after v2.8 milestone initialized)

**Core value:** Every user who wants to understand their civic world can do so freely; those who want to participate can do so with trust, identity, and shared purpose — at their own pace, never dragged.
**Current focus:** Milestone complete
**Last shipped:** v2.7 Source Integrity — Phases 100–104, shipped 2026-06-07. All 9 requirements closed (SRCA-01/02, FEDX-01/02, STAX-01/02/03, QUAL-01/02). MASTER-DELETION-LOG.md finalized. Archive: .planning/milestones/v2.7-ROADMAP.md (to be created at milestone close).

## Current Position

Phase: Milestone v2.8 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-06-08 — Milestone v2.8 completed and archived

## Performance Metrics

**v2.8 Scope — District of Columbia Coverage — IN PROGRESS**

- Phases: 3 (105–107)
- Requirements: 0/13 closed (DCIN-01/02/03/04, DCOF-01/02/03/04, DCST-01/02/03, DCFI-01/02)
- Plans complete: 0
- Started: 2026-06-07

**v2.7 Scope — Source Integrity — COMPLETE ✅**

- Phases: 5 (100–104)
- Requirements: 9/9 closed (SRCA-01/02, FEDX-01/02, STAX-01/02/03, QUAL-01/02)
- Plans complete: 9
- Started: 2026-06-05
- Completed: 2026-06-07

**v2.6 Scope — Data Quality & Elections — COMPLETE ✅**

- Phases: 5 (87, 88, 89, 90, 99)
- Requirements: 12/12 closed (SACC-01/02/03/04, GAPF-01/02, FINA-01/02/03, ELEC-01/02/03)
- Plans complete: 19
- Shipped: 2026-06-05

**v2.4 Scope — 2026 Senate Candidates — COMPLETE ✅**

- Phases: 2 (75–76)
- Requirements: 7/7 (RACE-01, CAND-01–03, SRES-01–03 all closed)
- Plans complete: 5 (Phase 75: 1/1, Phase 76: 4/4)
- Shipped: 2026-05-22

**v2.3 Scope — US Senate Coverage — COMPLETE ✅**

- Phases: 3 (72–74)
- Requirements: 8/8 (SINF-01–02, SENA-01–03, SSTA-01–03) — all closed
- Plans complete: 7 (Phase 72: 1/1, Phase 73: 2/2, Phase 74: 3/3 + script work)
- Shipped: 2026-05-21

**v2.2 Scope — TIGER District Geofencing — COMPLETE**

- Phases: 3 (69–71) ✅
- Requirements: 14/14 (GEO-01–14) ✅

**v2.1 Scope — COMPLETE**

- Phases: 3 (66–68) ✅
- Requirements: 21/21 (IBAK-01–06, LHUB-01–02, ISUP-01–04, IPRO-01–06, CEXP-01–03)

### v2.8 Requirements

| Req | Phase | Description |
|-----|-------|-------------|
| DCIN-01 | 105 | `essentials.governments` stub for Washington D.C. |
| DCIN-02 | 105 | District records — 8 CITY_COUNCIL ward districts, 9 SCHOOL_BOARD seats, 1 NATIONAL_LOWER for EHN |
| DCIN-03 | 105 | TIGER 2024 DC ward boundary polygons (8 wards) imported into `essentials.geo_districts` (CITY_COUNCIL layer) with GIST index |
| DCIN-04 | 105 | `tiger_geoid` backfilled on DC ward district records for Path 0 dual-column join |
| DCOF-01 | 105 | Politician + office records for Mayor Bowser + all 13 DC Council members |
| DCOF-02 | 105 | Politician + office records for AG Schwalb + 2 Shadow Senators |
| DCOF-03 | 105 | Politician + office records for all 9 SBOE members |
| DCOF-04 | 105 | `photo_origin_url` populated for all new DC officials; EHN verified and updated if missing |
| DCST-01 | 106 | Sourced stances for Mayor + DC Council + AG — city-scope topics (housing, homelessness, climate, civil rights, childcare, immigration, taxes, voting) |
| DCST-02 | 106 | Sourced stances for all 9 SBOE members — education topics (school vouchers, childcare, civil rights) |
| DCST-03 | 106 | Sourced stances for Shadow Senators + EHN — DC statehood / voting rights focus; EHN gaps filled |
| DCFI-01 | 107 | FEC `finance_summary` fetched and stored for Eleanor Holmes Norton |
| DCFI-02 | 107 | DC OCF data researched for Mayor + Council; populated where accessible machine-readable data exists |
| Phase 106 P01 | 90 | - tasks | - files |
| Phase 106 P02 | 5m | 3 tasks | 3 files |

### v2.8 Phase Dependencies

```
Phase 105 (DC Infrastructure + Official Records)
  └── Phase 106 (DC Stance Research)   — needs politician records as FK targets
  └── Phase 107 (DC Finance)           — needs politician records for finance_summary writes
```

### v2.8 Requirement Coverage

| Phase | Requirements | Count |
|-------|-------------|-------|
| 105 — DC Infrastructure + Official Records | DCIN-01, DCIN-02, DCIN-03, DCIN-04, DCOF-01, DCOF-02, DCOF-03, DCOF-04 | 8 |
| 106 — DC Stance Research | DCST-01, DCST-02, DCST-03 | 3 |
| 107 — DC Finance | DCFI-01, DCFI-02 | 2 |
| **Total unique** | | **13 / 13** ✓ |

### v2.7 Requirements

| Req | Phase | Description |
|-----|-------|-------------|
| SRCA-01 | 100 | DB audit report — total stances, % sourced, breakdown by tier |
| SRCA-02 | 100 | Prioritized target list — politicians with unsourced stances, ranked by tier + prominence |
| FEDX-01 | 101 | Every US Senator stance: sourced or deleted (Chair methodology) |
| FEDX-02 | 102 | Every US House rep stance: sourced or deleted (Chair methodology) |
| STAX-01 | 103 | Every CA state legislator (assembly + senate) stance: sourced or deleted |
| STAX-02 | 103 | MD officials in DB (migrations 269–271): research and add stances with sources from scratch |
| STAX-03 | 104 | Every city official (SF, SJ, SD, Berkeley, Fremont) stance: sourced or deleted |
| QUAL-01 | 101, 102, 103, 104 | Every stance updated/added: value verified against specific Chair text |
| QUAL-02 | 101, 102, 103, 104 | Deletion log produced (politician full_name, topic_key, former value, reason) |
| Phase 104 P01 | 30m | 3 tasks | 8 files |

### v2.7 Phase Dependencies

```
Phase 100 (Source Coverage Audit)
  └── Phase 101 (Federal Senate Remediation)     — target list from 100 scopes senate work
  └── Phase 102 (Federal House Remediation)      — target list from 100 scopes house work
  └── Phase 103 (State Remediation — CA + MD)    — target list from 100 scopes CA work; MD is new research
  └── Phase 104 (Local Remediation — City)       — target list from 100 confirms city state; final log here
```

### v2.7 Requirement Coverage

| Phase | Requirements | Count |
|-------|-------------|-------|
| 100 — Source Coverage Audit | SRCA-01, SRCA-02 | 2 |
| 101 — Federal Senate Remediation | FEDX-01, QUAL-01, QUAL-02 | 3 |
| 102 — Federal House Remediation | FEDX-02, QUAL-01, QUAL-02 | 3 |
| 103 — State Remediation — CA + MD | STAX-01, STAX-02, QUAL-01, QUAL-02 | 4 |
| 104 — Local Remediation — City Officials | STAX-03, QUAL-01, QUAL-02 | 3 |
| **Total unique** | | **9 / 9** ✓ |

Note: QUAL-01 and QUAL-02 are cross-cutting methodology requirements. They are assigned to every remediation phase (101–104) because each phase is responsible for applying the Chair verification standard and logging deletions. They are not a separate deliverable phase.

### v2.5 Requirements

| Req | Phase | Description |
|-----|-------|-------------|
| CITY-01 | 77 | Government stubs for San Jose, San Diego, Berkeley, Fremont in essentials.governments |
| CITY-02 | 77 | City council district records for all 4 cities in essentials.districts (CITY_COUNCIL type) |
| CITY-03 | 77 | Politician records for all San Jose city officials |
| CITY-04 | 77 | Politician records for all San Diego city officials |
| CITY-05 | 77 | Politician records for all Berkeley city officials |
| CITY-06 | 77 | Politician records for all Fremont city officials |
| CITY-07 | 77 | Office records for all new officials linked to correct city council districts |
| CITY-08 | 77 | photo_origin_url populated for all new officials |
| CSTA-01 | 78 | Stance research + migration for all San Jose officials |
| CSTA-02 | 78 | Stance research + migration for all San Diego officials |
| CSTA-03 | 78 | Stance research + migration for all Berkeley officials |
| CSTA-04 | 78 | Stance research + migration for all Fremont officials |
| CSTA-05 | 78 | Every stance row paired with context row containing at least one source URL |
| GAPF-01 | 79 | Audit all existing politicians for < 10 stances; produce prioritized target list |
| GAPF-02 | 79 | Research and ingest missing stances for all identified targets |
| FINA-01 | 80 | finance_summary JSONB column added to inform.politicians; migration applied |
| FINA-02 | 80 | Finance data ingested for new city officials + top-priority existing politicians (FEC/FPPC) |
| FINA-03 | 80 | Finance summary surfaced on GET /api/essentials/politicians; backward-compatible |
| Phase 89-gap-fill-existing-politicians P02 | 180 | 4 tasks | 5 files |

### v2.5 Phase Dependencies

```
Phase 77 (City Infrastructure + Official Records)
  └── Phase 78 (City Stance Research)       — needs politician records as FK targets
        └── Phase 79 (Gap-fill)              — gap-fill audit includes new city officials
  Phase 80 (Campaign Finance)               — needs Phase 77 for city official FK targets
                                             — Phase 78 not hard dependency but typically sequential
```

### v2.3 Requirements

| Req | Phase | Description |
|-----|-------|-------------|
| SINF-01 | 72 | NATIONAL_UPPER district records for all 50 states in essentials.districts |
| SINF-02 | 72 | Government records in essentials.governments for all 50 states (stubs for missing states) |
| SENA-01 | 73 | All 100 119th Congress senators in essentials.politicians (90 new) |
| SENA-02 | 73 | All 100 senators have office records in essentials.offices with correct district_id |
| SENA-03 | 73 | All 100 senators have photo_origin_url from official Senate source or Wikipedia |
| SSTA-01 | 74 | All 100 senators have stances in inform.politician_answers for >= 30 applicable topics |
| SSTA-02 | 74 | Every stance paired with inform.politician_context containing at least one source URL |
| SSTA-03 | 74 | 8 existing senators with partial stances filled to full applicable-topic coverage |

### v2.3 Phase Dependencies

```
Phase 72 (Senate Infrastructure)
  └── Phase 73 (Senator Records)   — needs NATIONAL_UPPER districts for office FK
        └── Phase 74 (Stance Research + Ingestion) — needs politician records for FK targets
```

### v2.3 Scope Notes

- 10 senators already exist (CA: Padilla + Schiff, IN: Young + Banks, MA: Warren + Markey, ME: Collins + King, TX: Cornyn + Cruz)
- 8 of those 10 have partial stance data — Phase 74 fills gaps
- Last migration applied: 170; next migration is 171
- Of 43 total CompassV2 topics, ~30+ apply to federal officials (local-tier topics excluded)
- Stances in inform.politician_answers; sources in inform.politician_context (sources TEXT[] column)
- Use research-stances skill for Phase 74; batch by party or alphabetically (A–M, N–Z)

### v2.2 Requirements

| Req | Phase | Description |
|-----|-------|-------------|
| GEO-01 | 69 ✅ | PostGIS confirmed enabled; `essentials.geo_districts` table with layer discriminator + GIST index |
| GEO-02 | 69 ✅ | `connect.user_districts` table — cached district resolution per user, upsertable by layer |
| GEO-03 | 69 ✅ | `tiger_geoid` column added to `essentials.districts` |
| GEO-04 | 69 ✅ | `essentials.resolve_user_districts(lat, lng, layers[])` RPC — point-in-polygon, returns matching rows |
| GEO-05 | 69 ✅ | `essentials.cache_user_districts(user_id, lat, lng)` RPC — resolves and upserts into user_districts |
| GEO-06 | 69 ✅ | CA Assembly (80 districts) imported from TIGER 2024 SLDL shapefile |
| GEO-07 | 69 ✅ | CA Senate (40 districts) imported from TIGER 2024 SLDU shapefile |
| GEO-08 | 69 ✅ | US House CA (52 districts) imported from TIGER 2024 CD119 shapefile |
| GEO-09 | 69 ✅ | `tiger_geoid` backfilled on existing `essentials.districts` records for all 3 layers |
| GEO-10 | 70 ✅ | Location-set flow calls `cache_user_districts` after saving lat/lng |
| GEO-11 | 70 ✅ | `GET /api/account/districts` endpoint returns cached district results for authenticated users |
| GEO-12 | 70 ✅ | Politicians-representing-me query joins via `tiger_geoid` — no live geo lookup after first resolution |
| GEO-13 | 71 ✅ | School districts (unified, elementary, secondary) imported from TIGER 2024 |
| GEO-14 | 71 ✅ | School districts surface on profile + wire into politicians-representing-me query |

### v2.2 Spec

Full spec written: `.planning/quick/tiger-geofencing-spec.md`

**Phase 69 — TIGER Schema + Data Import**
Schema migrations (089, 090), TIGER import for CA Assembly/Senate + US House, tiger_geoid backfill. Requires `gdal` locally + Supabase direct DB connection.

**Phase 70 — Geofencing Backend Integration**
Wire `cache_user_districts` into location-set flow, add `GET /api/account/districts`, update politicians-representing-me to use `tiger_geoid` join.

**Phase 71 — School Districts + Profile Display (Phase 2)**
Unified/elementary/secondary school district import, profile display, politician link. School boards not yet in `essentials.politicians` — link when they are.

## Accumulated Context

### Key Decisions

Full key decisions log in PROJECT.md. All prior milestone decisions archived in milestones/.

### v2.8 Scope Notes (established 2026-06-07)

- **DC official count**: ~26 new politician records — Mayor (1), DC Council (13: Chairman + 8 ward + 4 at-large), AG (1), Shadow Senators (2), SBOE (9). Eleanor Holmes Norton already exists; verify and update.
- **District types**: CITY_COUNCIL for ward seats (8), SCHOOL_BOARD for SBOE seats (9), NATIONAL_LOWER for EHN at-large delegate seat (1). All FK to the DC government stub.
- **TIGER layer name**: Use `dc_ward` as the layer discriminator in `essentials.geo_districts` (consistent with `ca_assembly`, `ca_senate`, `us_house` pattern).
- **Topic scope by body**: Mayor + Council + AG → city-scope (housing, homelessness, climate, civil rights, childcare, immigration, taxes, voting). SBOE → education-scope (school vouchers, childcare, civil rights). Shadow Senators + EHN → DC statehood / voting rights focus + applicable federal topics for EHN.
- **FEC ingestion**: Use existing `backend/scripts/fix-fec-name-mismatches.ts` or the FEC ingestion script from Phase 90 for EHN. Her FEC committee ID should be resolvable by name search.
- **DC OCF**: DC Office of Campaign Finance (`ocf.dc.gov`) — assess whether structured/machine-readable data is accessible before attempting ingestion. If not, document and close DCFI-02 with the finding.
- **Migration numbers**: Last applied is 283 (from Phase 104). Next available: 284. (Note: migrations 282–283 are visible in git status as untracked — verify they are applied before writing 284.)

### v2.7 Source Integrity Patterns (established 2026-06-05)

- **"Sourced" definition**: A stance counts as sourced only when `inform.politician_context` row exists AND `sources` is non-null AND contains at least one URL that is not empty or a placeholder string. This operationalized standard was defined in Phase 100.
- **Chair methodology**: Every stance value verified against the specific stance text for that Chair position — the politician's known position must match the exact text, not just directional lean. Never infer from party affiliation.
- **Deletion log format**: Each deleted stance records: politician full_name, topic_key, former value, reason ("no evidence found" or "value incorrect and no correcting source found"). Log committed to repo (migration comment or standalone file).
- **QUAL-01/QUAL-02 are cross-cutting**: These methodology requirements apply to every remediation phase. Each phase that does remediation is responsible for applying them — they are not a separate phase.
- **Phase 100 gates all remediation**: Never start 101–104 without the target list from Phase 100. The audit reveals actual scale — remediation phases may be split further or batched differently based on what the audit finds.

### v2.5 Infrastructure Patterns (carry-forward from SF officials, migration 216)

- **City official schema**: Same pattern as SF officials — `essentials.governments` (stub row), `essentials.districts` (CITY_COUNCIL type, FK to government), `essentials.politicians`, `essentials.offices` (FK to district). SF officials (20 politicians, 366 stances) completed migration 216. Next migration: 217.
- **gen_migration.py**: Updated in v2.4 to support city-level topics and per-batch EXCLUDED_TOPICS. Use for all city official stance migrations.
- **EXCLUDED_TOPICS for city officials**: `data-centers` excluded per SF pattern. Check per-city scope — city-level topics (city_council, school_board) included for local officials.
- **researcher agent rate limit**: Run ONE agent at a time, maximum 2 concurrent. Never launch city batches in parallel.
- **External_id ranges consumed**: -400001 to -400090 (senators), -400101 to -400143 (2026 candidates). City officials should use a distinct negative range (e.g., -500001 onward for San Jose, -501001 for San Diego, etc.).
- **Migration number**: Last applied is 216. Next available: 217.

### v2.3 Senate Infrastructure Patterns (from 72-01)

- **government_id FK on NATIONAL_UPPER districts**: `essentials.districts.government_id UUID REFERENCES essentials.governments(id)` added in migration 174. All 50 NATIONAL_UPPER rows are now FK'd to a canonical state government row. Phase 73 senator office inserts should join through `NATIONAL_UPPER.state` to find the correct `district_id`.
- **IN duplicate governments**: Indiana has 22 identical "State of Indiana" rows in `essentials.governments`. Queries that resolve `government_id` for IN must use `ORDER BY g.id LIMIT 1` to avoid ambiguity. Do not attempt to deduplicate — these rows may have downstream references.
- **Migration number correction**: Original plan said 172; corrected to 174 because quick tasks 52-01 and 52-02 consumed 172 and 173 after the plan was authored. Always verify last applied migration before writing a new one.

### v2.3 Senator Records Patterns (from 73-01)

- **Bioguide pre-verification**: Before writing any senator migration, curl HEAD-check each flagged bioguide ID against `https://unitedstates.github.io/images/congress/225x275/{BIOGUIDE}.jpg`. If 404, fetch `legislators-current.yaml` from unitedstates/congress-legislators repo and grep for the senator's name to get the authoritative bioguide. H001102 for Cindy Hyde-Smith returned 404; correct ID is H001079 per legislators-current.yaml.
- **DB full_name check before name-based backfill SQL**: Always query the live DB (`SELECT p.full_name FROM essentials.politicians p JOIN essentials.offices o ... WHERE d.district_type = 'NATIONAL_UPPER'`) before writing `WHERE p.full_name = '...'` conditions. Adam Schiff's DB row is `'Adam B. Schiff'` (not `'Adam Schiff'`); wrong name silently matches 0 rows.
- **Recently-appointed senators not yet on unitedstates CDN**: Senators appointed <1yr ago may not have photos in the unitedstates.github.io CDN. For Husted (OH, Jan 2025) and Armstrong (OK, 2025), used official .senate.gov portrait URLs. Check CDN first; fall back to official senate.gov portrait if 404.
- **Appointed senator flags**: `is_appointed=true` on politician row + `is_appointed_position=true` on office row. Downstream consumers (representatives-me, stance comparisons) can filter out appointed senators for "elected representatives" views.
- **Last migration applied: 176** (plan 73-02). Next available: 177. External_id range for Phase 74 stance data: starts at -500001 (or any range outside -400001 to -400090 and existing negative IDs).
- **External_id range -400001 to -400042 consumed by 73-01 (AK-MS)**. Plan 73-02 must use -400043 onward (or any distinct range not overlapping -400001 to -400042).
- **Alex Padilla existing photo**: Padilla's row has a city-of-Inglewood URL (non-null). The IS NULL OR = '' guard correctly skips it. Verification by non-null count still passes. Acceptable.
- **Next migration number**: 176 (migration 175 consumed by plan 73-01).

### v2.2 Migration Signature-Change Pattern (from 71-02)

- **When changing a PostgreSQL function's parameter count**: `CREATE OR REPLACE FUNCTION` can only replace a function with the EXACT SAME signature. Adding or removing parameters creates a second overload. Always `DROP FUNCTION IF EXISTS schema.fn(old, arg, types)` first, then create the new version. Failing to drop creates two overloads — Postgres refuses to resolve ambiguous calls with "function is not unique", and if the Node backend swallows errors the failure is silent and hard to diagnose.
- **Migration 094 fixed migration 093**: 093 added a 4-arg `cache_user_districts` using CREATE OR REPLACE without dropping the 3-arg version → silent district-cache failures for all users. 094 applied `DROP FUNCTION IF EXISTS essentials.cache_user_districts(uuid, numeric, numeric)` to resolve.

### v2.2 Path 0 Fast Path Pattern (from 70-02)

- **Path 0 before Path 1**: In hot-path handlers, add a try/catch fast path that reads from the cache table BEFORE the existing fallback. On any failure, catch logs a single `console.warn` and falls through silently — never short-circuits to an error/204.
- **Both-column join for non-unique tiger_geoid**: `essentials.districts` has a `tiger_geoid` that is non-unique across SLDL/SLDU (e.g. assembly D20 and senate D20 both have `tiger_geoid='06020'`). Always filter on `(tiger_geoid, district_type)` together.
- **districtRows hoist**: Declare `let districtRows = []` BEFORE the try/catch so downstream code in the same handler can read `districtRows.length` to determine whether the cache was warm.
- **Fire-and-forget backfill pattern**: `void pool.query(...).catch(e => console.warn(...))` after `res.json()` and before `return`. Guard with `districtRows.length === 0` — only backfill when the user genuinely had no cache. Never `await` — response is already on the wire.
- **recache_user_districts_for_user over cache_user_districts**: The resolver RPC keeps lat/lng inside a SECURITY DEFINER body — they are never returned to Node. Use the `_for_user(uuid)` wrapper that handles the Vault decrypt internally.

### v2.2 Redistricting Patterns (from 70-03)

- **Operator bulk re-cache CLI pattern**: per-user RPC + bulk RPC + Node.js orchestrator with `--dry-run`, `--before=YYYY-MM-DD`, `--user=<uuid>` flags. Dry-run replicates SQL HAVING clause inline — no separate read RPC needed.
- **Bulk RPC exception isolation**: wrap each per-row call in `BEGIN … EXCEPTION WHEN OTHERS THEN RETURN QUERY SELECT uid, 0, 'error: '||SQLERRM END` so one bad user never aborts the batch.
- **`status='no_coords'` pattern**: Return a clean status row (not RAISE) when a user lacks consent or stored coords — lets batch callers tally without exception handling.
- **`layers_resolved=0` with status='ok'**: Signals out-of-CA (point resolved but matched zero TIGER districts). Node.js script logs UUID and tallies separately from errors.

### v2.2 Geospatial Patterns (from 69-01)

- **PostGIS calls inside SECURITY DEFINER functions with SET search_path = ''**: ALL PostGIS functions must be schema-prefixed as `public.ST_Contains`, `public.ST_SetSRID`, `public.ST_MakePoint`. Without `public.` prefix they are unresolvable when search_path is empty.
- **ST_MakePoint argument order**: `ST_MakePoint(lng, lat)` — X then Y (longitude first). Never reverse.
- **GIST index mandatory on geom column**: Without it, `ST_Contains` does a full table scan — unacceptable for point-in-polygon lookups across thousands of polygons.
- **Layer discriminator pattern**: Single `essentials.geo_districts` table with `layer TEXT NOT NULL` + `UNIQUE(layer, geoid)` — allows adding new district types (school districts in Phase 71) without schema changes.
- **Migration apply method (2026-05-09)**: Local Docker/Supabase not running; applied migrations directly via `psql` to remote Supabase using pooler DATABASE_URL. DDL transactions work correctly with the pooler at port 5432.
- **tiger_geoid is non-unique**: SLDL and SLDU share geoid format (06NNN), so assembly D20 and senate D20 both have tiger_geoid='06020'. Phase 70 joins MUST use both `tiger_geoid` AND `district_type` to disambiguate. Layer→type: `ca_assembly`→`STATE_LOWER`, `ca_senate`→`STATE_UPPER`, `us_house`→`NATIONAL_LOWER`.
- **Session pooler for Windows ogr2ogr imports**: Direct Supabase host (`db.*.supabase.co`) DNS fails (IPv6). Use session pooler `aws-0-*.pooler.supabase.com:5432` for all pgclient connections. PROJ_LIB must also be set: `export PROJ_LIB="C:/Program Files/GDAL/projlib"`.

### v2.1 DB Patterns (from 66-01)

- **inform.inform_profiles auto-creation**: `trg_create_inform_profile` AFTER INSERT trigger on `public.users` calls `inform.handle_new_user()` (SECURITY DEFINER, `SET search_path = ''`) — same pattern as connect/empower tier auto-profile creation.
- **Yellow gem transfer on Connect**: `signup_with_invite` does `SELECT yellow_gem_balance FOR UPDATE` on inform_profiles (prevents concurrent award race), zeros the balance, then seeds `connected_profiles.gem_balance_yellow = COALESCE(v_inform_balance, 0)` — atomically within the RPC transaction.
- **IF FOUND guard on zero-out**: inform_profiles UPDATE only fires when row exists — handles users created before trigger deployment.
- **inform schema NOT in PostgREST**: all reads/writes to `inform.*` must use `pool.query()` (direct postgres), never PostgREST/supabaseAdmin.schema('inform').

### v2.0 Copy Decisions (from Phase 61)

- **AppNav**: No "Civic Platform" text — logo only. Wordmark belongs to auth pages, not the nav chrome.
- **Signup heading**: "Create your Connected Account" — names the tier (Connected) explicitly.
- **Legal name copy**: "During Alpha, your identity is verified through our invite network — one person, one voice." — "Never shown publicly" removed because legal name may surface on Empowered accounts in future features.
- **WelcomeScreen heading**: "Join to participate" — invitational, not "Get started" or conversion-funnel language.
- **AuthInput inputClassName**: escape-hatch for per-field styling (e.g., `font-mono tracking-wider` on invite code) without touching base styles.

### v2.0 Component Patterns (from 60-02, 60-03, 60-04)

**Chrome components (60-04):**

- **StepProgress bar height**: `h-1.5` (6px) — thinner than DashboardPage XP bar (`h-2`) per v2.0 spec
- **StepProgress fill**: `bg-ev-blue` (NOT ev-teal) — v2.0 primary CTA blue palette
- **Conditional slot pattern**: `{children && <div className="flex items-center gap-3">{children}</div>}` — avoids empty flex spacing
- **No Link/a on logo**: AppNav logo has no wrapper — navigation belongs to the consumer page
- **AppNav dimensions**: `max-w-lg` container, `h-14` height (56px), `sticky top-0 z-10` — matches DashboardPage header

### v2.0 Component Patterns (from 60-02, 60-03)

**Button components (60-03):**

- **PrimaryButton palette**: `bg-ev-blue text-white` / hover: `bg-ev-blue/90` / shape: `w-full rounded-xl py-3 font-bold text-base`
- **SecondaryButton palette**: `bg-gray-800 text-white border border-gray-700` / hover: `bg-gray-700` — gray-800 chosen (not ev-navy) so it layers above AuthCard's gray-900 background
- **Prop parity**: both buttons share identical interface (children/onClick/type/disabled/className with same defaults) — swap by changing only the import name
- **type defaults to 'button'**: forms must explicitly pass `type="submit"` — prevents accidental submission outside form context
- **No loading prop**: loading text is consumer responsibility via children

### v2.0 Component Patterns (from 60-02)

- **AuthCard base classes**: `bg-gray-900 rounded-2xl border border-gray-800 p-6 space-y-5` — no width; parent owns sizing
- **AuthCard background**: `bg-gray-900` not `bg-ev-navy` — card must contrast against navy page background
- **AuthInput onChange**: `(value: string) => void` — component extracts e.target.value; caller receives string
- **AuthInput focus ring**: `focus:ring-ev-blue` solid (no opacity variant) per design spec
- **AuthInput error state**: switches to `border-ev-red focus:ring-ev-red` + renders `<p className="text-ev-red">` below input
- **Component export convention**: named `export function X`, `interface` for props — matches AuthGuard.tsx pattern

### v2.0 Design Constraints

- **App surface only** — All v2.0 work is in `app/src` (end-user app at `app.empowered.vote`). Admin tool (`admin/src`) and contributor portal (`/contributor`) are out of scope.
- **`ev-blue` token also goes in admin** — DSGN-01 adds `ev-blue` to both `app/src/index.css` and `admin/src/index.css`; admin is otherwise untouched.
- **No Framer** — end-user frontend is the `/app` React app in this repo, not Framer. All v2.0 UI work goes in `app/src`.
- **Tailwind v4 `@theme`** — color tokens defined via `@theme` block in index.css, same pattern as existing `ev-red`, `ev-teal`, etc. in admin.
- **InformLanding routing** — unauthenticated root (`/`) renders `InformLandingPage`; authenticated root renders `DashboardPage`. Phase 64 owns the routing split.
- **Activity feed endpoint** — `GET /api/account/me/activity` reads from `connect.xp_transactions` (the existing append-only ledger). Returns last 20 entries. Requires Connected tier. Shipped 63-01.
- **FIX-01 CLOSED (63-01)** — invite label round-trip confirmed working end-to-end: DashboardPage sends `label`, invites.ts reads it, inviteQuotaService passes it as `$2` to the RPC. Phase 59 rename (`optional_name` → `label`) already resolved the bug. No code change needed.
- **`description` aliases `source` in /me/activity (63-01)** — `xp_transactions` has no `description` column; API maps `source` into `description` to keep contract clean and decouple frontend from schema column names.

### v2.0 Phase Dependencies

```
Phase 60 (Design Foundation)
  └── Phase 61 (Auth Flow Restyle)       — needs AuthCard, AuthInput, PrimaryButton, AppNav, StepProgress
  └── Phase 62 (Onboarding Restyle)      — needs AppNav, StepProgress, AuthCard, AuthInput, PrimaryButton
                                           — needs WelcomeScreen from Phase 61 to exist before removing WelcomeStep
  └── Phase 63 (Profile Page + Activity) — needs design tokens only (no auth-flow dependency)
  └── Phase 64 (InformLanding)           — needs AppNav with auth links
  └── Phase 65 (Dashboard Redesign)      — needs Phase 60 tokens + Phase 63 API + Phase 64 routing split
```

### v2.0 Requirement Coverage

| Phase | Requirements | Count |
|-------|-------------|-------|
| 60 — Design Foundation | DSGN-01, DSGN-02, DSGN-03, DSGN-04, DSGN-05, DSGN-06 | 6 |
| 61 — Auth Flow Restyle | AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, AUTH-06 | 6 |
| 62 — Onboarding Restyle | ONBD-01, ONBD-02, ONBD-03, ONBD-04, ONBD-05 | 5 |
| 63 — Profile Page + Activity Feed | PROF-01, PROF-02, PROF-03, PROF-04, PROF-05, PROF-06, API-01, FIX-01 | 8 |
| 64 — InformLanding | LAND-01, LAND-02, LAND-03, LAND-04, LAND-05 | 5 |
| 65 — Dashboard Redesign | DASH-01, DASH-02, DASH-03, DASH-04 | 4 |
| **Total** | | **34 / 34** ✓ |

### v2.1 Requirement Coverage

| Phase | Requirements | Count |
|-------|-------------|-------|
| 66 — Inform Profiles Backend Foundation | IBAK-01, IBAK-02, IBAK-03, IBAK-04, IBAK-05, IBAK-06 | 6 |
| 67 — Login Hub + Inform Signup Flow | LHUB-01, LHUB-02, ISUP-01, ISUP-02, ISUP-03, ISUP-04 | 6 |
| 68 — Yellow Inform Profile Page + Connected Explainer | IPRO-01, IPRO-02, IPRO-03, IPRO-04, IPRO-05, IPRO-06, CEXP-01, CEXP-02, CEXP-03 | 9 |
| **Total** | | **21 / 21** ✓ |

### v2.1 Phase Dependencies

```
Phase 66 (Inform Profiles Backend Foundation)
  └── Phase 67 (Login Hub + Inform Signup Flow) — needs DB trigger so signup auto-creates inform_profiles row
  └── Phase 68 (Yellow Inform Profile Page)     — needs /me inform_profile object (Phase 66) + signup creates the account (Phase 67)
```

### v2.5 Requirement Coverage

| Phase | Requirements | Count |
|-------|-------------|-------|
| 77 — City Infrastructure + Official Records | CITY-01, CITY-02, CITY-03, CITY-04, CITY-05, CITY-06, CITY-07, CITY-08 | 8 |
| 78 — City Stance Research | CSTA-01, CSTA-02, CSTA-03, CSTA-04, CSTA-05 | 5 |
| 79 — Gap-fill Existing Politicians | GAPF-01, GAPF-02 | 2 |
| 80 — Campaign Finance Schema + Ingestion + API | FINA-01, FINA-02, FINA-03 | 3 |
| **Total** | | **18 / 18** ✓ |

### v2.3 Requirement Coverage

| Phase | Requirements | Count |
|-------|-------------|-------|
| 72 — Senate Infrastructure | SINF-01, SINF-02 | 2 |
| 73 — Senator Records | SENA-01, SENA-02, SENA-03 | 3 |
| 74 — Stance Research + Ingestion | SSTA-01, SSTA-02, SSTA-03 | 3 |
| **Total** | | **8 / 8** ✓ |

### v2.6 Stance Accuracy Retro — Audit Findings (2026-06-02)

Statistical audit across ~1,049 politicians, ~13,700 rows. ~204 flagged (1.5%). Problem is concentrated.

**Confirmed systematic inversions — full re-research needed (Phase 81):**

- Jeff Gonzalez (R, CA Assembly) — 17 flags, all stances read as progressive Democrat
- Roger Niello (R, CA State Sen.) — 11 flags, same pattern
- Angie Nixon (D, FL Senate cand.) — 10 flags, every topic locked at =4
- Alex Vindman (D, FL Senate cand.) — 9 flags, abortion=5 religious-freedom=5
- Tim Grayson (D, CA State Sen.) — 9 flags, civil-rights=5 climate=5 SSM=5
- Ashley Hinson (R, IA Senate cand.) — 9 flags, abortion=2 climate=2 immigration=2
- Derek Dooley (R, GA Senate cand.) — 9 flags, same pattern as Hinson
- Adam Hinojosa (listed as D) — 6 flags, values look Republican — party tag may be wrong

**Legitimate despite flags — do NOT correct:**

- Collins, Murkowski, Tillis, Young, Capito: SSM=2 ✓ (all voted for Respect for Marriage Act)
- Gary VanDeaver (R-TX): school-vouchers=2 ✓ (voted against TX voucher bills)

**Ukraine-support: 26 Republicans at value=2** — needs individual verification (Phase 82)
**Party string inconsistency:** "Democrat" vs "Democratic" — needs normalization (Phase 82)

**Proposed v2.6 structure:**

- Phase 81: Re-research 8 confirmed inversions
- Phase 82: Borderline cases + ukraine-support audit + party string cleanup
- Phase 83: Embed "five chairs" framing into researcher agent system prompt

### Open Blockers

None for v2.8 start.

**Carried forward from v1.9 (non-blocking):**

- Verify `app.empowered.vote` in Render `CORS_ORIGIN` env var
- Smoke-test admin grant UI → adminRouter → grant_role RPC chain end-to-end in production
- Backport district-join approach to `getMatchingGrant` (compass_stance_editor — currently fail-open)
- v1.6 phases 42–43 (Decommission + DNS, Integration Documentation) still pending

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 003 | Expose jurisdiction fields on GET /api/account/me for VQ | 2026-03-18 | 6932815 | [003-expose-jurisdiction-location-fields-on-g](./quick/003-expose-jurisdiction-location-fields-on-g/) |
| 004 | Implement POST /api/vq/adjust-vr endpoint for Yellow quest VR adjustment | 2026-03-18 | 6f78510 | [004-implement-post-api-vq-adjust-vr-endpoin](./quick/004-implement-post-api-vq-adjust-vr-endpoin/) |
| 005 | Fix double-login: hash-fragment SSO loop between accounts and profile apps | 2026-03-18 | 7b6be4a | [005-fix-double-login-accounts-to-profile](./quick/005-fix-double-login-accounts-to-profile/) |
| 006 | Configure /app for Render static site deploy (profile.empowered.vote) | 2026-03-18 | df0a9b7 | [006-configure-app-render-static-site-deploy](./quick/006-configure-app-render-static-site-deploy/) |
| 007 | Admin access requests panel + Resend email notification on new submissions | 2026-03-19 | 4a2bb7a | [007-admin-access-requests-panel-and-notifications](./quick/007-admin-access-requests-panel-and-notifications/) |
| 008 | Fix representatives/me to return precise results for Connected users | 2026-03-29 | 8dfa38e | [008-fix-representatives-me-to-return-precise](./quick/008-fix-representatives-me-to-return-precise/) |
| 009 | Add weekly district staleness check cron for Connected users | 2026-03-29 | 10e5447 | [009-add-weekly-district-staleness-check-cron](./quick/009-add-weekly-district-staleness-check-cron/) |
| 010 | Fix BUG-01: restore deleted district rows for 54 CA Cicero politicians + quarantine CAL Access committee records | 2026-03-30 | dd06d9f | [010-fix-bug-01-restore-cicero-districts-quarant](./quick/010-fix-bug-01-restore-cicero-districts-quarant/) |
| 011 | Fix BUG-03: city/local officials missing from GET /essentials/representatives/me | 2026-03-30 | 64ccc0a | [011-fix-bug-03-city-officials-in-representatives](./quick/011-fix-bug-03-city-officials-in-representatives/) |
| 012 | Fix CA NATIONAL_UPPER senators (Padilla + Schiff) missing from geofence search | 2026-03-30 | 1b95f0e | [012-fix-ca-national-upper-senators-padilla-geofence](./quick/012-fix-ca-national-upper-senators-padilla-geofence/) |
| 013 | Phase 43 — Integration Documentation for Chris Andrews' team | 2026-03-30 | 85267c1 | [013-phase-43-integration-documentation-for-chri](./quick/013-phase-43-integration-documentation-for-chri/) |
| 014 | Add City Council district to jurisdiction data (connected_profiles + DashboardPage) | 2026-04-09 | c88eee1 | [014-add-city-council-district-to-jurisdicti](./quick/014-add-city-council-district-to-jurisdicti/) |
| 015 | Session polling for cross-app logout sync | 2026-04-09 | 091fb16 | [015-session-polling-cross-app-logout-sync](./quick/015-session-polling-cross-app-logout-sync/) |
| 016 | CA SoS 2026 challenger ingestion — 49 challengers across 16 LA County Primary races | 2026-04-13 | cfc2f40 | [016-ca-sos-challenger-ingestion](./quick/016-ca-sos-challenger-ingestion/) |
| 017 | Import verified 2026 LA County primary candidates | 2026-04-13 | — | [017-import-verified-2026-la-county-primary-c](./quick/017-import-verified-2026-la-county-primary-c/) |
| 018 | Add municipality_geo_id support so LA City races display for LA residents | 2026-04-13 | — | [018-add-municipality-geo-id-support-so-la-ci](./quick/018-add-municipality-geo-id-support-so-la-ci/) |
| 019 | Rename accounts.empowered.vote → login.empowered.vote in runtime code | 2026-04-15 | ac151ef | [019-rename-accounts-to-login-empowered-vote](./quick/019-rename-accounts-to-login-empowered-vote/) |
| 020 | FC post history tab on DashboardPage — PostHistory component with cursor pagination | 2026-04-17 | 0da4072 | [020-build-fc-post-history-feature-on-account](./quick/020-build-fc-post-history-feature-on-account/) |
| 021 | Add candidate support to compass compare — getCandidates()/getCandidateAnswers() + GET /candidates/:id/answers + GET /politicians?include_candidates=true | 2026-05-14 | 5eb3852 | [021-add-candidate-support-to-compass-compar](./quick/021-add-candidate-support-to-compass-compar/) |
| 022 | Fix Malik inversion bug, run 24 stance ingest scripts (255 rows), extend compassService dual-path fallback to politician_answers | 2026-05-15 | 01b3bfe | [022-run-pending-stance-ingest-and-extend-ca](./quick/022-run-pending-stance-ingest-and-extend-ca/) |

## Session Continuity

Last session: 2026-06-08
Stopped at: Phase 108 context captured
Resume file: .planning/phases/108-la-county-city-officials/108-CONTEXT.md

## Decisions

- [Phase ?]: Research technique for MA legislators

## Operator Next Steps

- `/clear` then `/gsd-plan-phase 108` — plan LA County city officials
- Phase 109 (LA County Finance) to be discussed after Phase 108 ships
