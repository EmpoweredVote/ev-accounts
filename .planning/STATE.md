# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-09 after v1.3 milestone start)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** Defining requirements for v1.3

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-03-09 — Milestone v1.3 started

Progress: — (v1.3 not yet planned)

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

Full key decisions log in PROJECT.md. v1.2 decisions committed to decisions table.

### v1.3 Architecture Decisions (made during milestone scoping)

- **Location: encrypted lat/lng, not formatted address string** — Store only coordinates (pgcrypto via Supabase Vault). Formatted address string is discarded after geocoding. Coordinates are never returned in any API response.
- **Jurisdiction endpoint pattern** — `/api/account/me/jurisdiction` is the only exit path for location data. Returns city/state/county/district_ids. Raw coordinates never leave the accounts system.
- **PostGIS internal, Indiana-scoped for Alpha** — No third-party geographic API (avoids sending coordinates externally). Load TIGER/Line Indiana boundaries into Supabase PostGIS. Expand to full US by loading more boundary data when scaling beyond pilot.
- **location_consent flag on connected_profiles** — `/api/account/me/jurisdiction` returns 403 without consent. Set during Connect flow with explicit user consent.
- **Multi-currency gems: extend existing ledger** — Add gem_type ENUM('yellow','blue','red') to connect.gem_transactions + 3 balance columns on connected_profiles. Single ledger, single advisory lock pattern. No separate tables per currency.
- **empowered_profiles politician columns designed as VQ output target** — Full field set (representing_city, representing_state, district_type, district_label, district_id, chamber_name, chamber_name_formal, government_name, office_title, is_vacant, is_candidate) matches Essentials consumed fields and maps to VQ consensus record structure.
- **Central profile page: API + UI** — /api/account/profile/:userId (aggregated) + profile page UI in accounts React app. Features link/embed rather than managing own profile views.

### Open Blockers (carried from v1.2)

- **Migrations 026–029 not applied to live DB** — Being addressed in v1.3 Phase 17.
- **CompassV2 frontend CV2-01 through CV2-05** — Accounts side addressed in v1.3; CompassV2 repo must implement its side separately.

### Pending Todos

None.

## Session Continuity

Last session: 2026-03-09
Stopped at: v1.3 milestone scoping complete — proceeding to requirements definition
Resume file: None
Resume: Continue from requirements definition phase.
