---
gsd_state_version: 1.0
milestone: v2.14
milestone_name: MA City Expansion Wave 2
status: executing
last_updated: "2026-06-16T07:20:00.000Z"
last_activity: "2026-06-16 — Phase 123-03 executed: migrations 710-712 applied; 23 per-ward district rows (waltham=9, medford=8, new-bedford=6) + 15 office re-links; MAGE-20/21/22 district+re-link steps complete"
progress:
  total_phases: 5
  completed_phases: 3
  total_plans: 10
  completed_plans: 12
  percent: 72
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-15 after v2.13 milestone complete)

**Core value:** Every user who wants to understand their civic world can do so freely; those who want to participate can do so with trust, identity, and shared purpose — at their own pace, never dragged.
**Current focus:** v2.14 — MA City Expansion Wave 2 (Phases 120–124)
**Last shipped:** v2.13 MA City Council District Geofencing — Phase 119, shipped 2026-06-15. Per-ward Path 0 geofencing for 6 MA cities (Boston/Worcester/Springfield/Lowell/Brockton/Quincy); migrations 659–664; MAGE-10..15 all pass.

## Current Position

Phase: Phase 123 — Ward Geofencing — All 7 Cities (IN PROGRESS)
Plan: 123-01-PLAN.md ✅ COMPLETE — load-ma-ward-boundaries.ts extended (11 CITY_CONFIGS entries); 54 X0014 ward polygons loaded for all 7 cities; migrations 706-712 pre-flight guards unblocked
Plan: 123-02-PLAN.md ✅ COMPLETE — Migrations 706-709 applied; 31 per-ward district rows (newton=8, somerville=7, lynn=7, fall-river=9) with tiger_geoid; 22 office re-links; MAGE-16/17/18/19 district steps done
Plan: 123-03-PLAN.md ✅ COMPLETE — Migrations 710-712 applied; 23 per-ward district rows (waltham=9, medford=8, new-bedford=6) with tiger_geoid; 15 office re-links; MAGE-20/21/22 district+re-link steps done
Status: Phase 123 COMPLETE (3 plans done) — all 7 cities geofenced; 54 total per-ward district rows + 37 total office re-links; Phase 124 gate verification next
Last activity: 2026-06-16 — Phase 123-03 executed: migrations 710-712 applied; 23 per-ward district rows + 15 office re-links; all post-verification gates PASSED; MAGE-20/21/22 complete

Phase: Phase 122 — Stance Research Wave 2: Lynn/Fall River/Waltham/New Bedford (COMPLETE ✅)
Plan: 122-01-PLAN.md ✅ COMPLETE — Migration 701 applied; Raposo/Pereira/Hart each 1 stance; Canuel honest-skip; MAST-04 satisfied
Plan: 122-02-PLAN.md ✅ COMPLETE — Migration 702 applied; Baptiste 1 stance + Lopes 2 stances gap-filled; Pemberton honest-skip; MAST-07 satisfied
Plan: 122-03-PLAN.md ✅ COMPLETE — Migrations 690-698 tracked (Waltham ward councillors); all 12 SQL assertions pass; MAST-03/04/05/07 complete
Status: Phase 122 COMPLETE — MAST-03 ✅ MAST-04 ✅ MAST-05 ✅ MAST-07 ✅; all 12 gate assertions passed; verify-phase-122.sql written
Last activity: 2026-06-16 — Phase 122-03 executed: MAST-03/04/05/07 gate passed; Lynn/Fall River/Waltham/New Bedford all covered; migrations 690-698 tracked; all 12 assertions pass

Phase: Phase 121 — Stance Research Wave 1: Newton/Somerville/Medford (COMPLETE ✅)
Plan: 121-01-PLAN.md ✅ COMPLETE — Migration 700 applied; Liz Mullane 6 stances + 6 context rows; MAST-06 satisfied
Plan: 121-02-PLAN.md ✅ COMPLETE — Phase gate: all 9 SQL assertions passed; MAST-01/02/06 marked complete
Status: Phase 121 COMPLETE — MAST-01 ✅ MAST-02 ✅ MAST-06 ✅; all 9 gate assertions passed; verify-phase-121.sql written
Last activity: 2026-06-16 — Phase 121 executed: MAST-01/02/06 gate passed; Liz Mullane (Medford) addressed via migration 700

Phase: Phase 120 — MA City Officials Seeding (COMPLETE ✅)
Plan: 120-02 ✅
Status: Phase 120 complete — MAOF-01..07 all pass; migration 687 applied; 9/9 gate assertions confirmed; Phases 121–123 unblocked
Last activity: 2026-06-15 — Phase 120 executed and verified

---

## Previous Milestone Position (v2.13 — COMPLETE ✅)

Phase: 119-ma-city-council-district-geofencing — COMPLETE ✅
Plan: 119-01-PLAN.md ✅ COMPLETE — migration 659 applied; Boston 9 X0013 + 2 citywide rows have tiger_geoid [MAGE-10]
Plan: 119-02-PLAN.md ✅ COMPLETE — Worcester Tier 3: 5 X0014 polygons + migration 660 (5 district rows + 5 re-links) [MAGE-11]
Plan: 119-03-PLAN.md ✅ COMPLETE — Springfield/Lowell/Brockton/Quincy Tier 3: 29 X0014 polygons + migrations 661-664 [MAGE-12..15]
Plan: 119-04-PLAN.md ✅ COMPLETE — Phase gate: 8 SQL assertions pass + Path 0 human-approved for all 6 cities [MAGE-10..15]
Status: Phase 119 complete — MAGE-10 ✅ MAGE-11 ✅ MAGE-12 ✅ MAGE-13 ✅ MAGE-14 ✅ MAGE-15 ✅; per-ward Path 0 geofencing confirmed for Boston/Worcester/Springfield/Lowell/Brockton/Quincy; human verify approved 2026-06-15.
Last activity: 2026-06-15

Phase: 118-ma-tiger-geofencing — COMPLETE ✅
Plan: 118-01-PLAN.md ✅ COMPLETE
Plan: 118-02-PLAN.md ✅ COMPLETE
Plan: 118-03-PLAN.md ✅ COMPLETE
Status: Phase 118 complete — all MAGE-00..05 gates pass; tiger_geoid backfilled on 200 MA state districts; Medford geo_id corrected; Path 0 confirmed for Porter Square Cambridge (STATE_LOWER 25083 + STATE_UPPER 25D27); human verify approved 2026-06-15.
Last activity: 2026-06-15

## Performance Metrics

**v2.14 Scope — MA City Expansion Wave 2 — IN PROGRESS**

- Phases: 5 (120–124)
- Requirements: 0/21 closed
- Plans complete: 0
- Started: 2026-06-15

**v2.13 Scope — MA City Council District Geofencing — COMPLETE**

- Phases: 1 (119)
- Requirements: 6/6 closed (MAGE-10..15)
- Plans complete: 4
- Shipped: 2026-06-15

**v2.12 Scope — MA Expansion — COMPLETE**

- Phases: 2 (117–118)
- Requirements: all closed (7 MA cities + MAGE-00..05)
- Plans complete: 6
- Shipped: 2026-06-15

### v2.14 Requirements

| Req | Phase | Description |
|-----|-------|-------------|
| MAOF-01 | 120 | Newton district + politician + office records |
| MAOF-02 | 120 | Somerville district + politician + office records |
| MAOF-03 | 120 | Lynn district + politician + office records |
| MAOF-04 | 120 | Fall River district + politician + office records |
| MAOF-05 | 120 | Waltham district + politician + office records |
| MAOF-06 | 120 | Medford district + politician + office records |
| MAOF-07 | 120 | New Bedford district + politician + office records |
| MAST-01 | 121 | Sourced stances + context for Newton officials |
| MAST-02 | 121 | Sourced stances + context for Somerville officials |
| MAST-06 | 121 | Sourced stances + context for Medford officials |
| MAST-03 | 122 | Sourced stances + context for Lynn officials |
| MAST-04 | 122 | Sourced stances + context for Fall River officials |
| MAST-05 | 122 | Sourced stances + context for Waltham officials |
| MAST-07 | 122 | Sourced stances + context for New Bedford officials |
| MAGE-16 | 123 | Newton ward polygons + tiger_geoid backfill + Path 0 |
| MAGE-17 | 123 | Somerville ward polygons + tiger_geoid backfill + Path 0 |
| MAGE-18 | 123 | Lynn ward polygons + tiger_geoid backfill + Path 0 |
| MAGE-19 | 123 | Fall River ward polygons + tiger_geoid backfill + Path 0 |
| MAGE-20 | 123 | Waltham ward polygons + tiger_geoid backfill + Path 0 |
| MAGE-21 | 123 | Medford ward polygons + tiger_geoid backfill + Path 0 |
| MAGE-22 | 123 | New Bedford ward polygons + tiger_geoid backfill + Path 0 |

### v2.14 Phase Dependencies

```
Phase 120 (MA City Officials Seeding)                   — no dependencies; pure migration work
  └── Phase 121 (Stance Research Wave 1: Newton/Somerville/Medford)  — needs Phase 120 FK targets
  └── Phase 122 (Stance Research Wave 2: Lynn/Fall River/Waltham/New Bedford) — needs Phase 120 FK targets
  └── Phase 123 (Ward Geofencing — All 7 Cities)        — needs Phase 120 district geo_ids
Phase 124 (Phase Gate Verification)                     — needs Phases 120–123 complete
```

Note: Phases 121, 122, and 123 can run in parallel once Phase 120 is complete. Stance phases (121, 122) must run one city at a time within each wave (rate limit concern). Geofencing cities in Phase 123 can be batched in a single plan.

### v2.14 Requirement Coverage

| Phase | Requirements | Count |
|-------|-------------|-------|
| 120 — MA City Officials Seeding | MAOF-01..07 | 7 |
| 121 — Stance Research Wave 1 | MAST-01, MAST-02, MAST-06 | 3 |
| 122 — Stance Research Wave 2 | MAST-03, MAST-04, MAST-05, MAST-07 | 4 |
| 123 — Ward Geofencing All 7 Cities | MAGE-16..22 | 7 |
| 124 — Phase Gate Verification | cross-cutting gate for all 21 | — |
| **Total unique** | | **21 / 21** ✓ |

### v2.14 Scope Notes (established 2026-06-15)

- **Migration numbering**: Current DB max is 674. Next available migration: 675. Phase 120 starts at 675 (one per city = 7 migrations, 675–681).
- **Cities already in DB**: Each of the 7 cities has a government stub + 1 chamber record. Zero districts, politicians, or offices exist yet.
- **Officials seeding order**: Follow v2.12 Phase 117 pattern — `essentials.governments` → `essentials.chambers` (already exists) → `essentials.districts` → `essentials.politicians` → `essentials.offices`. One migration per city for clean rollback isolation.
- **Stance research pattern**: Run one city at a time (rate limit concern, per MEMORY.md). Newton/Somerville/Medford in Wave 1 (Phase 121), Lynn/Fall River/Waltham/New Bedford in Wave 2 (Phase 122). Wave grouping mirrors v2.12 Phase 117 approach.
- **Geofencing pattern**: Phase 123 follows Phase 119 pattern — ogr2ogr import from city GIS sources + psql backfill migration. PROJ_LIB on this machine: `C:\Program Files\GDAL\projlib`. Session pooler: `aws-0-*.pooler.supabase.com:5432`.
- **MAGE numbering**: MAGE-16..22 continues from v2.13 (MAGE-10..15). MAGE-16 = Newton, MAGE-17 = Somerville, MAGE-18 = Lynn, MAGE-19 = Fall River, MAGE-20 = Waltham, MAGE-21 = Medford, MAGE-22 = New Bedford.
- **Phase 121 includes Medford (MAST-06)**: Medford is grouped with Newton/Somerville (smaller cities with likely limited records) rather than Wave 2. Adjust if Medford proves larger.
- **Phase 124 gate script**: Follow `verify-phase-119.sql` pattern (labeled SQL assertions, one per MAOF/MAST/MAGE requirement). Store at `backend/scripts/verify-phase-120-124.sql`.

## Accumulated Context

### Key Decisions

Full key decisions log in PROJECT.md. All prior milestone decisions archived in milestones/.

### v2.13 Scope Notes (carry-forward)

- **Tiger_geoid backfill pattern**: For city council districts, `tiger_geoid` = city FIPS code padded to match `geo_districts.geoid` format. Always join on `(tiger_geoid, district_type)` — SLDL/SLDU share geoid format.
- **ogr2ogr + psql pattern**: Use `ogr2ogr -f PostgreSQL PG:"..." input.shp -nln essentials.geofence_boundaries`. Session pooler IPv4 on Windows. PROJ_LIB must be set.
- **Phase gate SQL pattern**: 8 labeled assertions, one per MAGE requirement. `ASSERT` or `DO $$ BEGIN IF NOT (...) THEN RAISE EXCEPTION ... END IF; END $$;` style.
- **MAGE-05 filter**: Always add `mtfcc IN ('G5210','G5220')` when querying geofence_boundaries for MA state legislative layers — geo_id '25017' exists in both Middlesex County and 8th Bristol SLDL.

### v2.12 Scope Notes (carry-forward)

- **512 stances, 71 officials**: v2.12 covered Boston/Cambridge/Worcester/Springfield/Lowell/Brockton/Quincy.
- **Migration chunking**: If a stance SQL file exceeds Supabase editor limit, split into _chunk_1, _chunk_2, etc. Apply via execute_sql (not apply_migration for multi-chunk files).
- **`BEGIN;` in one execute_sql + `COMMIT;` in another = silent rollback**: Use auto-commit for multi-chunk idempotent migrations.
- **Cambridge officials**: query by district_id `cf3274f9-48c3-4e96-8273-3f6574add756`, not government_id (NULL on Cambridge districts).

### Open Blockers

None for v2.14 start.

**Carried forward from v1.9 (non-blocking):**

- Verify app.empowered.vote in Render CORS_ORIGIN env var
- Smoke-test admin grant UI → adminRouter → grant_role RPC chain end-to-end in production
- Backport district-join approach to getMatchingGrant (compass_stance_editor — currently fail-open)
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
| 019 | Rename accounts.empowered.vote to login.empowered.vote in runtime code | 2026-04-15 | ac151ef | [019-rename-accounts-to-login-empowered-vote](./quick/019-rename-accounts-to-login-empowered-vote/) |
| 020 | FC post history tab on DashboardPage — PostHistory component with cursor pagination | 2026-04-17 | 0da4072 | [020-build-fc-post-history-feature-on-account](./quick/020-build-fc-post-history-feature-on-account/) |
| 021 | Add candidate support to compass compare | 2026-05-14 | 5eb3852 | [021-add-candidate-support-to-compass-compar](./quick/021-add-candidate-support-to-compass-compar/) |
| 022 | Fix Malik inversion bug, run 24 stance ingest scripts (255 rows), extend compassService dual-path fallback | 2026-05-15 | 01b3bfe | [022-run-pending-stance-ingest-and-extend-ca](./quick/022-run-pending-stance-ingest-and-extend-ca/) |

## Session Continuity

Last session: 2026-06-16T07:20:00.000Z
Stopped at: Completed Phase 123-03 (migrations 710-712 applied; Waltham 9-ward + Medford 8-ward at-large + New Bedford 6-ward; MAGE-20/21/22 complete)
Resume file: None

## Decisions

- [Phase 118-01]: Migration number 619 (not 600) — disk files 600–618 already taken by Phase 117 stance files; DB MAX was 604 at execution time; disk wins
- [Phase 118-01]: PROJ_LIB path is C:\Program Files\GDAL\projlib (not C:\OSGeo4W\share\proj as documented in CONTEXT.md)
- [Phase 118-02]: Migration number 622 (not 601) — DB MAX was 619; disk highest was 621 (621_malakie_stances.sql); use 622 for Medford fix + city tiger_geoid backfill
- [Phase 118-03]: MAGE-05 requires mtfcc IN ('G5210','G5220') filter — geo_id '25017' exists as both Middlesex County (G4020) and 8th Bristol SLDL District (G5220); unfiltered subquery returns 3 rows; mtfcc filter returns correct 2 rows
- [Phase 114]: FEC /candidates/search/ principal_committees uses .committee_id not .id — fix field name in fetchFecData()
- [Phase 114]: Use DIRECT_FEC_ID_OVERRIDES for stale congress-legislators YAML entries (Ivey H2MD04232, Self H2TX00064)
- [Phase 114]: resolveViaDirectSearch restricted to known CA House members (LaMalfa/Swalwell) — hardcodes state=CA,office=H so must not run for other politicians
- [Phase 114]: politician_sources has no unique constraint on (essentials_politician_id, source_system) — use DELETE+INSERT for DIRECT path upsert
- Phase 111 scoped to senators only — VAST-01 (VA state executives) was descoped from Phase 111; not yet assigned to a phase
- psql-applied wave migrations (326–330) do NOT insert rows into `supabase_migrations.schema_migrations` — always pre-flight with SELECT MAX(version) before each wave, not STATE.md cache
- Wave migration DO $$ verification must use `pc.politician_id IS NULL` not `pc.id IS NULL` — `inform.politician_context` has composite PK (politician_id, topic_id), no standalone `id` column
- 5 honest-skipped senators (Head SD-3, Hackworth SD-5, Mulchi SD-9, Cifers SD-10, Srinivasan SD-32) — no documentable policy positions; VAST-02 satisfied as 35/40 with 5 documented skips
- [Phase 122-02]: Migration 702 supersedes honest-skip migrations 654/656/657 — prior agents did not fetch NB Light parking minimums article (Feb 2026) or Oct 2025 candidate interview pages
- [Phase 122-02]: Pemberton honest-skip — voted yes on parking minimums but no attributed statement found; vote alone without reasoning does not satisfy evidence-only rule
- [Phase 122-02]: Baptiste residential-zoning=1 sourced from NB Light Feb 13 2026 article; direct quote "you gotta be crazy" meets evidence standard
- [Phase 122-02]: Lopes public-safety-approach=4 + housing=3 both sourced from Oct 2025 NB Light candidate interviews
- [Phase 123-03]: Migration 711 uses '2539835' (corrected Medford FIPS) NOT '2540115' (Melrose FIPS from migration 591 bug) — citywide geo_id asymmetry documented in Pitfall 4 of RESEARCH.md
- [Phase 123-03]: Medford Step 5 omitted — charter reform 2020 creates fully at-large council; migration 711 follows 709 (Fall River) at-large pattern with 2-gate post-verification only
- [Phase 123-03]: Waltham ward councillors are sequential (external_ids -2572600008=Ward1 through -2572600016=Ward9) — unlike Newton which is non-sequential (Pitfall 3)

## Operator Next Steps

- v2.14 roadmap created (2026-06-15) — 5 phases (120–124), 21 requirements
- Start: `/gsd:plan-phase 120` — MA City Officials Seeding (MAOF-01..07)
  - One migration per city (Newton, Somerville, Lynn, Fall River, Waltham, Medford, New Bedford)
  - Migration range: 675–681 (current DB max: 674)
  - Pattern: governments stub already exists; add districts → politicians → offices
- Then: Phase 121 (Newton/Somerville/Medford stances) and Phase 123 (geofencing) can be planned in parallel once Phase 120 complete
- Phase 122 (Lynn/Fall River/Waltham/New Bedford stances) follows after Phase 121 validates the wave methodology
- Phase 124 (phase gate) is last — requires all others complete
