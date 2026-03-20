# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-19 after v1.5 milestone completion)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** Planning next milestone — run `/gsd:new-milestone`

## Current Position

Phase: Not started (defining requirements for Platform Consolidation)
Plan: —
Status: Defining requirements for v1.6 Platform Consolidation
Last activity: 2026-03-19 — v1.6 milestone pivoted to Platform Consolidation

Progress: [v1.0 ✅][v1.1 ✅][v1.2 ✅][v1.3 ✅][v1.4 ✅][v1.5 ✅] 33/33 phases shipped ██████████

## Accumulated Context

### Key Decisions

Full key decisions log in PROJECT.md. All v1.5 decisions archived in milestones/v1.5-ROADMAP.md.

v1.5 patterns established (apply going forward):
- **Integration guide format** — 10-section structure (quick ref → context → auth → reads → writes → profile → jurisdiction → migration → errors → checklist)
- **Anti-patterns inline** — place at point of relevance (not consolidated at bottom); AI/dev encounters the warning at the exact decision point
- **Inform is the unconditional baseline** — partner features must work for anonymous users; Connected enhances, never gates
- **Never prompt for location consent in partner apps** — accounts app owns consent exclusively; others read jurisdiction if present

### Open Blockers

- **Essentials provisioning** — `essentials-rep-lookup` XP source not yet in `serviceKeyAuth.ts`; `GEMS_SERVICE_KEYS` env var provisioning needed before first Essentials production award. Flagged in guide.
- **CompassV2 frontend** — integration guide complete (`docs/COMPASSV2-INTEGRATION.md`). CompassV2 repo must implement its side. No remaining blocker on accounts side.

### v1.6 Candidates

- ROLES-01: Scoped roles system — replace flat `is_admin` with feature-scoped permissions (Dev access, community admin, compass curator)
- VR-F01: VR admin dashboard — visualize Verification Rating data across users
- COMP-05: User-to-user compass compare — infrastructure in place, politician compare only in v1
- Essentials XP source provisioning + GEMS_SERVICE_KEYS documentation fix

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 003 | Expose jurisdiction fields on GET /api/account/me for VQ | 2026-03-18 | 6932815 | [003-expose-jurisdiction-location-fields-on-g](./quick/003-expose-jurisdiction-location-fields-on-g/) |
| 004 | Implement POST /api/vq/adjust-vr endpoint for Yellow quest VR adjustment | 2026-03-18 | 6f78510 | [004-implement-post-api-vq-adjust-vr-endpoin](./quick/004-implement-post-api-vq-adjust-vr-endpoin/) |
| 005 | Fix double-login: hash-fragment SSO loop between accounts and profile apps | 2026-03-18 | 7b6be4a | [005-fix-double-login-accounts-to-profile](./quick/005-fix-double-login-accounts-to-profile/) |
| 006 | Configure /app for Render static site deploy (profile.empowered.vote) | 2026-03-18 | df0a9b7 | [006-configure-app-render-static-site-deploy](./quick/006-configure-app-render-static-site-deploy/) |
| 007 | Admin access requests panel + Resend email notification on new submissions | 2026-03-19 | 4a2bb7a | [007-admin-access-requests-panel-and-notifications](./quick/007-admin-access-requests-panel-and-notifications/) |

### Pending Todos

None.

## Session Continuity

Last session: 2026-03-19
Stopped at: Quick task 007 complete (admin access requests panel + email notifications)
Resume: Continue `/gsd:new-milestone` — research in progress for v1.6
