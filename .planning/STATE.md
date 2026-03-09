# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-09 after v1.3 milestone start)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** Phase 17 — Live Alpha Deployment

## Current Position

Phase: 17 of 23 (Live Alpha Deployment)
Plan: — (not yet planned)
Status: Ready to plan
Last activity: 2026-03-09 — v1.3 roadmap created (7 phases, 29 requirements mapped)

Progress: [░░░░░░░░░░] 0% (v1.3 not yet executed)

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

### Open Blockers

- **Migrations 026–029 not applied to live DB** — Phase 17 addresses this.
- **CompassV2 frontend CV2-01 through CV2-05** — Accounts side addressed in Phase 18; CompassV2 repo must implement its side separately.

### Pending Todos

None.

## Session Continuity

Last session: 2026-03-09
Stopped at: v1.3 roadmap created — 7 phases (17–23), 29 requirements mapped, all files written
Resume: Run `/gsd:plan-phase 17` to begin Live Alpha Deployment planning.
