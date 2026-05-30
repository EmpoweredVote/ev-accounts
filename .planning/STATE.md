---
gsd_state_version: 1.0
milestone: v1.6
milestone_name: Platform Consolidation
status: Milestone complete
last_updated: "2026-05-28T15:07:18.488Z"
last_activity: 2026-05-28 -- Phase 78 execution started
progress:
  total_phases: 10
  completed_phases: 8
  total_plans: 30
  completed_plans: 29
  percent: 80
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-19 after v2.3 milestone start)

**Core value:** Every user who wants to understand their civic world can do so freely; those who want to participate can do so with trust, identity, and shared purpose — at their own pace, never dragged.
**Current focus:** Phase 78 — city-stance-research
**Last shipped:** Phase 76 complete 2026-05-22: 715 stance rows across 43 non-incumbent Senate candidates (migrations 197, 198, 207). Armstrong (OK) 14→17 stances, Husted (OH) 24→30 stances (migration 210). SRES-01, SRES-02, SRES-03 verified. James Byrd (WY, D) at 5 stances — documented floor case (no evidence available). v2.4 milestone complete.

## Current Position

Phase: 78 (city-stance-research) — EXECUTING
Plan: 1 of 6
**v2.5 City Officials Expansion — roadmap created 2026-05-22. 4 phases (77–80), 18 requirements. Run /gsd:plan-phase 77 to begin.**

v2.0 roadmap: 6 phases (60–65), 34 requirements. Phase 60–63 shipped. Phase 64–65 pending.
v2.1 roadmap: created 2026-04-27. 3 phases (66–68), 21 requirements. ALL COMPLETE.
v2.2 roadmap: TIGER District Geofencing. 3 phases (69–71). ALL COMPLETE 2026-05-10. GEO-01 through GEO-14 shipped.
v2.3 roadmap: US Senate Coverage. 3 phases (72–74). 8 requirements. ALL COMPLETE 2026-05-21. SINF-01–02, SENA-01–03, SSTA-01–03 all closed.
v2.4 roadmap: 2026 Senate Candidates. 2 phases (75–76). 7 requirements. ALL COMPLETE 2026-05-22. RACE-01, CAND-01–03, SRES-01–03 all closed.
v2.5 roadmap: City Officials Expansion. 4 phases (77–80). 18 requirements. PENDING.

Phase 60 (Design Foundation) shipped 2026-04-25: 4/4 plans, DSGN-01–06 verified.
Phase 61 (Auth Flow Restyle) shipped 2026-04-25: 5/5 plans, AUTH-01–06 verified.
Phase 62 (Onboarding Restyle) shipped 2026-04-25: 3/3 plans, ONBD-01–05 verified.
Phase 63 (Profile Page + Activity Feed) shipped 2026-04-27: API-01 + FIX-01 closed (63-01); PROF-01–06 completed in admin/src/pages/ProfilePage.tsx (login.empowered.vote/profile, built 2026-04-26). 63-02 closed as superseded — duplicate app/src profile page not needed; canonical profile is login.empowered.vote/profile.
Phase 64 (InformLanding): SKIPPED 2026-05-10 — superseded by login.empowered.vote/profile.
Phase 65 (Dashboard Redesign): SKIPPED 2026-05-10 — users go to login.empowered.vote/profile, not app.empowered.vote.
Phase 66 (Inform Profiles Backend Foundation) shipped 2026-04-27: 3/3 plans, IBAK-01–06 verified. inform.inform_profiles table live, trigger active, backfill done, gem routing tier-branched, /me inform_profile field live, PATCH /location-hint live, signup_with_invite gem transfer deployed.
Phase 67 (Login Hub + Inform Signup Flow) shipped 2026-04-27: 3/3 plans complete, LHUB-01–02 + ISUP-01–04 closed. 67-01: yellow "Create an Account" CTA + InformConstraintsModal on Login page. 67-02: InformSignup.tsx at /signup/inform — three-field form, yellow theming, posts to /api/auth/signup without invite_code. 67-03: display_name persisted to public.users on Inform signup path.
Phase 68 (Yellow Inform Profile Page + Connected Explainer) shipped 2026-05-09: 2/2 plans, IPRO-01–06 + CEXP-01–03 verified. Yellow Inform profile branch complete — tier pill, compass stat, lock badges, location label, bottom CTA, ConnectedExplainerModal (full infographic with dark mode, CTA analytics, limitations flow). Connected/Empowered pills now also open modal. UAT: 10/10 passed.
Phase 69 (TIGER Schema + Data Import): 2/2 plans complete 2026-05-10 — migrations 089, 090, 091 applied. GEO-01 through GEO-09 live. 172-row TIGER import (80 ca_assembly + 40 ca_senate + 52 us_house). tiger_geoid backfilled on all CA STATE_LOWER/STATE_UPPER/NATIONAL_LOWER rows. Verified 10/10 must-haves.
Phase 70 (Geofencing Backend Integration): ALL 4 PLANS COMPLETE 2026-05-10. GEO-10 + GEO-11 shipped (70-01): cache_user_districts wired into set-location (Connected) and location-hint (Inform); GET /api/account/districts live. GEO-12 shipped (70-02): Path 0 TIGER fast path added to GET /representatives/me — reads connect.user_districts, joins essentials.districts on (tiger_geoid, district_type), no live PostGIS lookup for cached users; Path 1.5 gains opportunistic backfill so pre-Phase-70 users self-promote to Path 0. Redistricting tooling (70-03): migration 092 applied — essentials.recache_user_districts_for_user + _bulk live; backend/scripts/recache-user-districts.ts operator CLI with --dry-run/--before/--user flags. 70-04: POST /api/account/set-location live for Inform tier (geocoding + JSONB persist + fail-open district cache + { ok: true } response). Phase 70 complete.
Phase 71 (School Districts + Profile Display): ALL 2 PLANS COMPLETE 2026-05-10. GEO-13 + GEO-14 shipped. Migration 093 applied — both resolve_user_districts and cache_user_districts now default to 6 layers (adds school_unified, school_elementary, school_secondary). CA school districts imported: 346 unified, 517 elementary, 112 secondary. GET /api/account/school-district endpoint live (204 on empty, 200 with { school_unified, school_elementary, school_secondary }). Path 0 layerTypeMap extended with SCHOOL_UNIFIED/SCHOOL_ELEMENTARY/SCHOOL_SECONDARY. Plan 71-02 COMPLETE (UAT approved): Location tab added to ProfilePage for all Connected users, SchoolDistrictSection component, legislative districts + City Council district display, school district Google search links, Connected-only recalibration form with force:true. Migration 094 applied — dropped ambiguous 3-arg cache_user_districts overload that caused "function is not unique" silent failures. v2.2 roadmap fully complete.

Phase 72 (Senate Infrastructure) COMPLETE 2026-05-19: 1/1 plans, SINF-01 + SINF-02 verified. Migration 174 applied — essentials.districts.government_id column added, 46 government stubs (MA + 45 states) created, 45 NATIONAL_UPPER districts added (CA/IN/MA/ME/TX already existed), CA junk row deleted, IN orphan row deleted + Todd Young reassigned. 50 NATIONAL_UPPER districts total, all FK'd to government rows.
Phase 74 (Stance Research + Ingestion) COMPLETE 2026-05-21: 15 research batches dispatched via research-stances skill. All 100 senators covered — 53 Republicans (batches 1–12 + Armstrong OK), 47 Democrats/Independents (batches 13–15). 1,006 Dem stances + Armstrong 14 stances pushed via typed push scripts. Armstrong (OK, appointed March 2026) replaced Mullin (resigned to become DHS Secretary). SSTA-01, SSTA-02, SSTA-03 closed.
Phase 73 (Senator Records) COMPLETE 2026-05-19:
  Plan 01: Migration 175 — 42 new senator rows (AK-MS, external_ids -400001 to -400042), 42 office rows, 42 photos (GitHub CDN). Bioguide correction: Cindy Hyde-Smith H001102→H001079.
  Plan 02: Migration 176 — 48 new senator rows (MT-WY, external_ids -400043 to -400090), 48 office rows, 48 photos. Bill Hagerty bioguide H001099→H000601. Husted (OH) + Armstrong (OK) appointed flags set. MA/ME/TX photo no-ops (already have Wikipedia URLs). SENA-01, SENA-02, SENA-03 closed.
  Final state: 100 senators, all 50 states × 2, 0 missing photos. Next migration: 177.

Phase 75 (Race Catalog + Candidate Records) COMPLETE 2026-05-22: 1/1 plans. Migration 196 applied — 43 non-incumbent 2026 Senate candidate politicians + offices + photos. RACE-01, CAND-01–03 closed.
Phase 76 (Candidate Stance Research) COMPLETE 2026-05-22: 4/4 plans. Migrations 197, 198, 207 (43 candidates, 715 stances) + migration 210 (Armstrong OK 14→17, Husted OH 24→30). SRES-01, SRES-02, SRES-03 closed. v2.4 milestone complete.

Last activity: 2026-05-28 -- Phase 78 execution started

**v1.9 Roles — SHIPPED 2026-04-06 ✅**
8 phases, 19 plans, 17/17 requirements. Archived to `.planning/milestones/v1.9-ROADMAP.md`.

**Phase 59 (Referral Code System) — SHIPPED 2026-04-08 ✅**
4 plans complete. Level-gated invite quota system with social accountability live.

Progress: [v1.0 ✅][v1.1 ✅][v1.2 ✅][v1.3 ✅][v1.4 ✅][v1.5 ✅][v1.6 🔄][v1.7 ✅][v1.8 ✅][v1.9 ✅][v2.0 ✅][v2.1 ✅][v2.2 ✅][v2.3 ✅][v2.4 ✅][v2.5 🔄] Phase 60 ✅ Phase 61 ✅ Phase 62 ✅ Phase 63 ✅ Phase 64 — Phase 65 — Phase 66 ✅ Phase 67 ✅ Phase 68 ✅ Phase 69 ✅ Phase 70 ✅ Phase 71 ✅ Phase 72 ✅ Phase 73 ✅ Phase 74 ✅ Phase 75 ✅ Phase 76 ✅ Phase 77 ⬜ Phase 78 ⬜ Phase 79 ⬜ Phase 80 ⬜

## Performance Metrics

**v2.5 Scope — City Officials Expansion — IN PROGRESS**

- Phases: 4 (77–80)
- Requirements: 0/18 closed (CITY-01–08, CSTA-01–05, GAPF-01–02, FINA-01–03)
- Plans complete: 0
- Started: 2026-05-22

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

### Open Blockers

None for v2.5 start.

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

Last session: 2026-05-22
Stopped at: v2.5 roadmap created — phases 77–80 defined. Run /gsd:plan-phase 77 to begin Phase 77 (City Infrastructure + Official Records).
Resume file: None
