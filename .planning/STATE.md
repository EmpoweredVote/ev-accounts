# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-19 after v1.6 milestone started)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** v1.6 Platform Consolidation — Phase 36: Express Ports Wave 1 — Treasury and Meetings

## Current Position

Phase: 36 — Express Ports Wave 1 (Treasury + Meetings)
Plan: 01 of 2 complete
Status: In progress — Plan 01 complete, Plan 02 pending
Last activity: 2026-03-20 — Completed 36-01-PLAN.md (Treasury service + routes)

Progress: [v1.0 ✅][v1.1 ✅][v1.2 ✅][v1.3 ✅][v1.4 ✅][v1.5 ✅][v1.6 🔄] 35/43 phases shipped (36 in progress) ████████░░

## Accumulated Context

### Key Decisions

Full key decisions log in PROJECT.md. All prior milestone decisions archived in milestones/.

v1.6 constraints and decisions to carry forward:
- **pool.query() for all non-public schema reads AND writes** — essentials schema is NOT in PostgREST exposed schema list (`public, connect, empower, inform, graphql_public, validation_quests`); `supabaseAnon.schema('essentials')` fails at runtime; all essentials access must use pool.query() (Phase 35 confirmed)
- **No nested SECURITY DEFINER calls** — gem/XP writes must be inline in atomic RPCs; established v1.4
- **SET search_path = '' on all new SECURITY DEFINER functions** — established v1.2; fully qualified table refs required
- **Two-pass validation in admin RPCs** — validate all inputs before any writes; established v1.2
- **RLS is primary defense** — EV-Backend tables currently have no RLS; adding RLS is required for every migrated table before any endpoints go live
- **Data import pipelines are out of scope** — Congress.gov, LegiScan, OpenStates are not ev-accounts' responsibility
- **Supabase management API for migrations** — Use `POST https://api.supabase.com/v1/projects/{ref}/database/query` with access token from MCP config when CLI pooler times out; returns 201 on DDL success

### Open Blockers

- **Essentials XP provisioning** — `essentials-rep-lookup` XP source not yet in `serviceKeyAuth.ts`; `GEMS_SERVICE_KEYS` env var provisioning needed before first Essentials production award. Deferred to v1.7.
- **EV-Backend Go source access** — Phase 34 schema inspection completed via Supabase MCP (direct DB). Go repo access not required for Phase 34.

### Phase 34 Key Findings (from 34-01)

- **69 tables across 6 schemas** — all RLS off, zero existing grants/policies (clean slate)
- **compass.user_id is text (UUID values)** — RLS policies must use `user_id::uuid = auth.uid()` cast
- **54 public-read / 4 owner-read / 8 authenticated-read** — policy category assignments complete
- **208,101 row baseline** — essentials dominates (206,587 rows); meetings and treasury are empty schemas
- **transparent_motivations.source_audit_log** — authenticated-read despite having `changed_by_user_id uuid` (admin audit log, not owner-scoped)

### v1.6 Phase Structure

| Phase | Name | Requirements | Key Risk |
|-------|------|--------------|----------|
| 34 | Database Schema Migration | CONS-01–04 | Row count verification on 52 tables |
| 35 | Politician Deduplication | CONS-05–07 | FK migration with zero data loss |
| 36 | Express Ports Wave 1 — Treasury + Meetings | CONS-08–09 | Response shape parity with Go |
| 37 | Express Ports Wave 2 — Staging | CONS-10 | Role-gated workflow coverage |
| 38 | Express Ports Wave 3 — Essentials | CONS-11 | PostGIS Census Geocoder integration |
| 39 | Compass Additions | CONS-12–13 | CHECK constraint migration on live data |
| 40 | Frontend Auth Updates | CONS-14–17 | Coordinated cutover across 4 apps |
| 41 | VQ and Trivia Migration | CONS-18–19 | DATABASE_URL swap + FK update |
| 42 | Decommission and DNS Cutover | CONS-20–22 | Zero-traffic verification before DNS flip |
| 43 | Integration Documentation | CONS-23 | Completeness for Chris Andrews' team |

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 003 | Expose jurisdiction fields on GET /api/account/me for VQ | 2026-03-18 | 6932815 | [003-expose-jurisdiction-location-fields-on-g](./quick/003-expose-jurisdiction-location-fields-on-g/) |
| 004 | Implement POST /api/vq/adjust-vr endpoint for Yellow quest VR adjustment | 2026-03-18 | 6f78510 | [004-implement-post-api-vq-adjust-vr-endpoin](./quick/004-implement-post-api-vq-adjust-vr-endpoin/) |
| 005 | Fix double-login: hash-fragment SSO loop between accounts and profile apps | 2026-03-18 | 7b6be4a | [005-fix-double-login-accounts-to-profile](./quick/005-fix-double-login-accounts-to-profile/) |
| 006 | Configure /app for Render static site deploy (profile.empowered.vote) | 2026-03-18 | df0a9b7 | [006-configure-app-render-static-site-deploy](./quick/006-configure-app-render-static-site-deploy/) |
| 007 | Admin access requests panel + Resend email notification on new submissions | 2026-03-19 | 4a2bb7a | [007-admin-access-requests-panel-and-notifications](./quick/007-admin-access-requests-panel-and-notifications/) |

### Pending Todos

- Confirm access to EV-Backend Go repo and production DB connection string before starting Phase 34.
- Coordinate with Chris Andrews on timing of frontend auth switches (Phase 40) — needs to be a planned cutover, not a rolling change.

### Phase 36 In Progress (plan 01 complete)

- **treasury schema served by ev-accounts Express** — CONS-08 fulfilled; Go server no longer needed for treasury data
- **pool.query() confirmed for treasury** — treasury schema not in PostgREST exposed list; all 9 service functions use direct SQL
- **Treasury currently 0 rows** — confirmed from Phase 34 baseline; reads return empty arrays (expected)
- **req.params as string cast** — TypeScript strict typing requires explicit cast on Express route params
- **Phase 36 Plan 02 (Meetings) unblocked**

### Phase 35 Complete (plans 01 + 02)

- **essentials.politicians is sole source of truth** — inform.politicians dropped in plan 01; all application code migrated in plan 02
- **essentials schema not PostgREST-exposed** — `supabaseAnon.schema('essentials')` fails; all essentials reads/writes must use `pool.query()` directly
- **PoliticianGroup response shape changed** — `GET /api/essentials/politicians` now returns `{ party, incumbent, candidates }` groups (was `{ office_title, incumbent, candidates }`)
- **PostgREST anti-pattern eliminated** — `adminSetPoliticianContext` now uses `pool.query()` with direct SQL upsert
- **Phase 36 (Express Ports Wave 1) unblocked** — ready to proceed

### Phase 35 Plan 01 Key Findings (from 35-01)

- **inform.politicians had 30 records, not 4** — research underestimated scope; 588 answers + 500 context rows fully migrated
- **empower.empowered_profiles undocumented FK** — `empowered_profiles_politician_id_fkey` referenced inform.politicians; all NULL values; reassigned to essentials
- **4 unmatched politicians identity-inserted into essentials** — Karen Bass, Nanette Barragan, Tony Cardenas, Gilbert Cisneros (preserve 82 answers + ~60 context rows)
- **Alex Padilla has 3 duplicate records in essentials** — selected UUID `2717ff94` (has office_id set); duplicates remain in essentials (EV-Backend data quality issue)
- **admin_list_politicians return shape changed** — removed inform-specific columns; now returns essentials-native fields (is_incumbent, party, party_short_name, slug, bio_text)
- **scripts/seedPoliticians.ts needs update** — still targets inform.politicians, will error on next run
- **FK drop ordering** — must drop FK constraints BEFORE UPDATE when reassigning to different parent table

### Phase 34 Complete (from 34-02)

- **RLS now enabled on all 69 tables across 6 schemas** — 62 policies applied in plan 02, 6 policies in plan 03
- **Policy breakdown:** 51 public-read, 8 authenticated-read, 4 owner-read (compass) + 6 authenticated-read (staging)
- **`supabase db query --linked --file`** — reliable migration method from local Windows environment (avoids pooler IPv4 timeout)
- **compass.user_id TEXT cast pattern** — `user_id::uuid = (select auth.uid())` confirmed in production
- **Phase 35 unblocked** — all RLS prerequisites complete; Politician Deduplication can proceed

## Session Continuity

Last session: 2026-03-20
Stopped at: Phase 36 Plan 01 complete — treasury service + routes (4c30b78); curl verification passed
Resume: Run `/gsd:execute-phase 36` to execute Plan 02 (Meetings routes)
