---
gsd_state_version: 1.0
milestone: v2.10
milestone_name: Virginia Coverage + LA County Finance
status: ready_to_plan
last_updated: 2026-06-09T05:02:35.593Z
last_activity: 2026-06-09 -- Phase 109 execution started
progress:
  total_phases: 5
  completed_phases: 0
  total_plans: 4
  completed_plans: 15
  percent: 0
stopped_at: Phase 109 complete (4/4) — ready to discuss Phase 110
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-08 after v2.9 milestone archived)

**Core value:** Every user who wants to understand their civic world can do so freely; those who want to participate can do so with trust, identity, and shared purpose — at their own pace, never dragged.
**Current focus:** Phase 110 — va official records + geofencing
**Last shipped:** v2.9 LA County Expansion — Phase 108, shipped 2026-06-08. All 6 requirements closed (LAOF-01–06). Archive: .planning/milestones/v2.9-ROADMAP.md.

## Current Position

Phase: 110
Plan: Not started
Status: Ready to plan
Last activity: 2026-06-09

## Performance Metrics

**v2.10 Scope — Virginia Coverage + LA County Finance — IN PROGRESS**

- Phases: 5 (109–113)
- Requirements: 0/15 closed (LAFI-01/02, VAIN-01/02/03, VAGE-01/02/03, VAST-01/02/03/04/05, VAFI-01/02)
- Plans complete: 0
- Started: 2026-06-08

**v2.9 Scope — LA County Expansion — COMPLETE**

- Phases: 1 (108)
- Requirements: 6/6 closed (LAOF-01–06)
- Plans complete: 5
- Shipped: 2026-06-08

**v2.8 Scope — District of Columbia Coverage — COMPLETE**

- Phases: 3 (105–107)
- Requirements: 13/13 closed (DCIN-01/02/03/04, DCOF-01/02/03/04, DCST-01/02/03, DCFI-01/02)
- Plans complete: 6
- Shipped: 2026-06-08

**v2.7 Scope — Source Integrity — COMPLETE**

- Phases: 5 (100–104)
- Requirements: 9/9 closed (SRCA-01/02, FEDX-01/02, STAX-01/02/03, QUAL-01/02)
- Plans complete: 9
- Shipped: 2026-06-07

**v2.6 Scope — Data Quality & Elections — COMPLETE**

- Phases: 5 (87, 88, 89, 90, 99)
- Requirements: 12/12 closed (SACC-01/02/03/04, GAPF-01/02, FINA-01/02/03, ELEC-01/02/03)
- Plans complete: 19
- Shipped: 2026-06-05

### v2.10 Requirements

| Req | Phase | Description |
|-----|-------|-------------|
| LAFI-01 | 109 | CAL-ACCESS data assessed; finance_summary ingested for LA City Mayor + all Council members + Controller + Clerk |
| LAFI-02 | 109 | Netfile assessed for other LA County cities; finance data ingested where accessible machine-readable data exists |
| VAIN-01 | 110 | Politician + office records for all 100 VA House delegates committed and applied (migration 308) |
| VAIN-02 | 110 | Politician + office records for 11 VA federal House reps committed and applied (migration 311) |
| VAIN-03 | 110 | photo_origin_url populated for all new VA officials (executives, senators, delegates, House reps) |
| VAGE-01 | 110 | TIGER 2024 VA SLDL polygons (100 House delegate districts) imported into essentials.geo_districts with GIST index |
| VAGE-02 | 110 | TIGER 2024 VA SLDU polygons (40 Senate districts) imported into essentials.geo_districts |
| VAGE-03 | 110 | tiger_geoid backfilled on all VA essentials.districts records for dual-column Path 0 join |
| VAST-01 | 111 | Sourced stances for VA state executives (Governor, Lt. Governor, AG) |
| VAST-02 | 111 | Sourced stances for all 40 VA state senators |
| VAST-03 | 112 | Sourced stances for all 100 VA House delegates (honest-skip where no documentable evidence) |
| VAST-04 | 113 | Sourced stances for 11 VA House reps (federal topics) |
| VAST-05 | 111, 112, 113 | Every new stance paired with inform.politician_context containing at least one real source URL |
| VAFI-01 | 113 | FEC finance_summary fetched and stored for all 11 VA House reps |
| VAFI-02 | 113 | VPAP data assessed for VA state officials; finance data ingested where machine-readable |

### v2.10 Phase Dependencies

```
Phase 109 (LA County Finance)               — independent of VA work; runs in parallel with Phase 110
Phase 110 (VA Official Records + Geofencing) — independent of Phase 109
  └── Phase 111 (VA State Stances - Execs + Senators) — needs politician records as FK targets
  └── Phase 112 (VA Delegate Stances)                 — needs delegate records as FK targets
  └── Phase 113 (VA Federal Stances + Finance)         — needs federal rep records as FK targets
```

### v2.10 Requirement Coverage

| Phase | Requirements | Count |
|-------|-------------|-------|
| 109 — LA County Finance | LAFI-01, LAFI-02 | 2 |
| 110 — VA Official Records + Geofencing | VAIN-01, VAIN-02, VAIN-03, VAGE-01, VAGE-02, VAGE-03 | 6 |
| 111 — VA State Stances - Executives + Senators | VAST-01, VAST-02, VAST-05 | 3 |
| 112 — VA Delegate Stances | VAST-03, VAST-05 | 2 |
| 113 — VA Federal Stances + Finance | VAST-04, VAST-05, VAFI-01, VAFI-02 | 4 |
| **Total unique** | | **15 / 15** ✓ |

Note: VAST-05 is a cross-cutting quality requirement (every new stance must have a sourced context row). It applies to Phases 111, 112, and 113 — each stance phase is responsible for enforcing it. It is not a separate deliverable phase.

### v2.10 Scope Notes (established 2026-06-08)

- **VA government + chambers already committed**: essentials.governments stub (migration 304), state executive + Senate chambers (migration 306), 40 state senators (migration 307) — these are in the DB. Only delegates (migration 308) and federal House reps (migration 311) are drafted but untracked.
- **Migration 308 and 311**: Both exist as untracked SQL files. Phase 110 reviews, renumbers if needed (last applied: 310), commits, and applies. Migration 311 may conflict with numbering — verify before applying.
- **VA TIGER pipeline**: Same ogr2ogr + psql approach as CA (Phases 69-71). VA SLDL (100 delegate districts, layer = 'va_sldl') and SLDU (40 senate districts, layer = 'va_sldu'). Standard TIGER 2024 files — no special MapServer needed unlike DC wards.
- **Finance tools**: FEC script from Phase 90 is reusable for VAFI-01 (11 VA House reps). VPAP (vpap.org) is the VA analog to CAL-ACCESS — assess machine-readability before attempting ingestion (VAFI-02).
- **LA finance tools**: CAL-ACCESS covers LA City; Netfile covers most other CA cities. finance_summary column already exists and is surfaced on API from v2.6.
- **VAST-05 cross-cutting**: Research-stances SKILL.md already enforces Chair methodology + real source URLs. Every stance written in Phases 111, 112, 113 must have a paired inform.politician_context row with at least one non-placeholder URL.
- **Stance scope for VA officials**: State executives + senators → state-scope topics. VA federal House reps → federal topics (same scope as US House reps in Phases 101-102). Delegates → state-scope topics, honest-skip for less prominent members with no public record.

## Accumulated Context

### Key Decisions

Full key decisions log in PROJECT.md. All prior milestone decisions archived in milestones/.

### v2.9 Scope Notes (carry-forward)

- **LA County 27 cities**: Phase 108 seeded complete elected governing bodies for 27 LA County cities across 4 waves. West Hollywood FIPS 0684410 verified via Census Geocoder API.
- **Phase gate pattern**: 8-assertion SQL script (backend/scripts/verify-la-county-108.sql) confirmed all Phase 108 deliverables. Same pattern applicable to Phase 110 VA verification.
- **Assertion 7 join bug pattern**: Found in Phase 108 review — always verify DISTINCT in count assertions when joining across offices-to-districts to avoid overcounting officials sharing a district.

### v2.8 Scope Notes (carry-forward)

- **DC official count**: 27 DC politician records in DB — Mayor (1), DC Council (13), AG (1), Shadow Senators (2), SBOE (9), EHN (1).
- **TIGER layer naming convention**: dc_ward, ca_assembly, ca_senate, us_house. VA should follow: va_sldl (STATE_LOWER), va_sldu (STATE_UPPER).
- **ogr2ogr + psql import**: Use session pooler aws-0-*.pooler.supabase.com:5432 (IPv4). PROJ_LIB must be set on Windows.
- **DROP FUNCTION before arity changes**: Always DROP FUNCTION IF EXISTS before creating new overload; CREATE OR REPLACE does not remove old arity.

### v2.7 Source Integrity Patterns (carry-forward)

- **"Sourced" definition**: A stance counts as sourced only when inform.politician_context row exists AND sources is non-null AND contains at least one URL that is not empty or a placeholder string.
- **Chair methodology**: Every stance value verified against the specific stance text for that Chair position — never infer from party affiliation.
- **Deletion log format**: politician full_name, topic_key, former value, reason.

### Open Blockers

None for v2.10 start.

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

Last session: 2026-06-09T00:35:55.252Z
Stopped at: context exhaustion at 75% (2026-06-09)
Resume file: None

## Decisions

(none for v2.10 yet)

## Operator Next Steps

- Phase 109 and Phase 110 have no dependency on each other — either can start first
- Recommended: `/gsd-plan-phase 109` for LA County Finance (faster win, no VA dependency)
- Or: `/gsd-plan-phase 110` for VA Official Records + Geofencing (unblocks 3 stance phases)
