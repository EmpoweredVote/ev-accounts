# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-09 after v1.3 milestone start)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** Phase 17 — Live Alpha Deployment

## Current Position

Phase: 17 of 23 (Live Alpha Deployment)
Plan: 1 of 2 in phase (17-01 complete)
Status: In progress
Last activity: 2026-03-09 — Completed 17-01-PLAN.md (migration apply script + deployment runbook)

Progress: [█░░░░░░░░░] ~7% (1 of ~14 v1.3 plans complete)

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

### Open Blockers

- **Migrations 026–029 not yet applied to live DB** — Tooling is ready (DEPLOY.md + applyMigrations.ts). Awaiting execution against production Supabase (Phase 17 plan 02 smoke tests).
- **CompassV2 frontend CV2-01 through CV2-05** — Accounts side addressed in Phase 18; CompassV2 repo must implement its side separately.

### Pending Todos

None.

## Session Continuity

Last session: 2026-03-09
Stopped at: Completed 17-01-PLAN.md — migration apply script and deployment runbook
Resume: Run `/gsd:execute-phase 17` with plan 17-02 to continue (smoke tests).
