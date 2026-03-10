# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-09 after v1.3 milestone start)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** Phase 18 — CompassV2 API Compatibility

## Current Position

Phase: 18 of 23 (CompassV2 API Contract)
Plan: 03 of 4 in phase
Status: In progress
Last activity: 2026-03-10 — Completed 18-03-PLAN.md (completed_onboarding root promotion + guest_state signup migration)

Progress: [████░░░░░░] ~29% (6 of ~14 v1.3 plans complete)

## Performance Metrics

**v1.0 shipped:**
- Total plans: 18 plans, 8 phases, 4 days

**v1.1 shipped:**
- Plans: 5 (09-01, 09-02, 10-01, 10-02, 11-01)
- Phases: 3 (Phase 9–11)
- Timeline: 1 day (2026-03-04)

**v1.2 shipped:**
- Plans: 15 (12-01 through 16-01)
- Phases: 5 (Phase 12–16)
- Timeline: 2 days (2026-03-06 → 2026-03-07)

## Accumulated Context

### Key Decisions

Full key decisions log in PROJECT.md. v1.3 architecture decisions:

- **Location: encrypted lat/lng, not formatted address string** — Store only coordinates (pgcrypto via Supabase Vault). Address string discarded after geocoding. Coordinates never returned in any API response.
- **PostGIS internal, Indiana-scoped for Alpha** — TIGER/Line Indiana boundaries loaded into Supabase PostGIS. No third-party geographic API. Expand by loading more boundary data when scaling.
- **Multi-currency gems: extend existing ledger** — Add gem_type ENUM to connect.gem_transactions + 3 balance columns on connected_profiles. Single advisory lock pattern.
- **empowered_profiles politician columns as VQ output target** — Full field set matches Essentials consumed fields and maps to VQ consensus record structure.
- **Direct DB connection for migrations** — DATABASE_URL must use db.<ref>.supabase.co:5432 (direct), never the pooler (pooler.supabase.com:6543). Multi-statement SQL fails on pooler. (17-01)
- **Idempotent migration script** — Pre-verify before apply (skip if already applied), post-verify after apply (exit 1 if failed). Safe to re-run. (17-01)
- **PostGIS + pgcrypto enabled at Alpha deploy** — Both extensions documented in DEPLOY.md Step 1 even though Phase 19 needs them. Avoids second deploy window. (17-01)
- **Smoke test auth check: 401 is the only pass** — 500 = Supabase auth unreachable, 200 = catastrophic. Each status has distinct diagnostic meaning. (17-02)
- **Admin UI check hardcoded as [SKIP]** — Programmatic JS error detection not feasible in a fetch-based script; kept visible in output for operator checklist. (17-02)
- **Essentials politicians check validates migration 026** — Endpoint queries is_candidate column; 500 response during Alpha deploy = migration not applied. (17-02)
- **NUMERIC(3,1) for compass values; bounds 0.5–5.5** — INT stances (1–5) coexist with write-in half-integer positions. Outer bounds allow placement just outside defined stance range. (18-01)
- **migrate_guest_compass_state uses ON CONFLICT DO NOTHING** — never overwrites post-signup activity; per-row FK exception handler skips stale topic IDs rather than aborting. (18-01)
- **upsert_compass_answer gains SET search_path = ''** — was absent from migration 025 version; brought in line with project SECURITY DEFINER conventions. (18-01)
- **Anonymous compass mode: optionalAuth + short-circuit guard** — five answer routes return empty data ([], null, { topic_ids: [] }) for unauthenticated callers; guard placed before Zod parse so unauthenticated requests never hit validation. (18-02)
- **PUT/GET /selected-topics unauthenticated: { topic_ids: [] } not NOT_CONNECTED** — NOT_CONNECTED is reserved for authenticated users without a connected_profiles row; unauthenticated users simply have no topics. (18-02)
- **completed_onboarding at root AND in connected_profile** — additive promotion; both locations populated so no existing callers break. Inform-tier gets false at root. (18-03)
- **guest_state migration non-fatal: try/catch swallows errors** — signup always returns 201 on success regardless of migration outcome; errors logged for ops visibility. (18-03)
- **signUpBodySchema separate from authBodySchema** — login keeps minimal schema; signup schema extension is isolated and does not affect login validation. (18-03)
- **p_selected_topics null (not []) when absent** — RPC null guard skips UPDATE to selected_topics when no topics provided, avoiding overwrite of existing data. (18-03)

### Open Blockers

- **PostgREST schema config requires DB-level override** — Supabase dashboard UI change was not picked up by PostgREST. Fixed via `ALTER ROLE authenticator SET pgrst.db_schemas TO '...'`. Document this in DEPLOY.md for future deploys.
- **CompassV2 frontend CV2-01 through CV2-05** — Accounts side addressed in Phase 18; CompassV2 repo must implement its side separately.

### Pending Todos

None.

## Session Continuity

Last session: 2026-03-10
Stopped at: Completed 18-03-PLAN.md — completed_onboarding promoted to /me root; POST /signup accepts guest_state with atomic RPC migration
Resume file: None
Resume: Execute plan 18-04 (final CV2 API compatibility tasks).
