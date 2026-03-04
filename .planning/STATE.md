# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-28 after v1.0 milestone)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** Hardening complete — ready to plan v1.1

## Current Position

Phase: All 8 phases complete — v1.0 SHIPPED + post-release hardening done
Plan: N/A
Status: Clean — tests green, architecture enforced, security hardened
Last activity: 2026-03-03 — Post-release hardening session

Progress: [████████████████████] 100% (v1.0 complete)

## Accumulated Context

### Decisions

Full key decisions log in PROJECT.md. All v1.0 decisions marked with outcomes.

### Pending Todos

- Run `supabase gen types --linked --lang typescript --schema public,connect,empower,inform > backend/src/types/database.types.ts` after applying migrations (inform schema + new public/connect tables added in hardening)
- Copy `backend/.env.example` to `backend/.env` and fill with real Supabase credentials

### Open Blockers / Hardening (v1.1 targets)

- COMP-05: User-to-user compass compare deferred (infrastructure in place)
- CIVIC-02: Gem reserve cap deferred for Alpha

### Hardening Completed (2026-03-03)

| Item | Resolution | Commits |
|------|-----------|---------|
| Supabase linter: `users_public` SECURITY DEFINER view | Restructured: new `users_public_data` table + `security_invoker = on` view + sync trigger | aa95ded |
| Supabase linter: RLS disabled on `spatial_ref_sys` | Enabled RLS (PostGIS system table; deny-by-default for app roles) | f558f36 |
| Architecture violations: `supabaseAdmin` in routes | Extracted to service files; new `connectService.ts` + `supabaseAnon` client; 7 new `compassService` functions | ea77aef |
| Auth test failures (connectivity-dependent) | Wrapped with `describe.skipIf(!hasRealSupabase)` | ea77aef |
| JWT logout TTL (~1h window) | Per-user `last_logout` timestamp in Redis/cache; `requireAuth` rejects tokens with `iat < last_logout` | 3dd8b61 |
| TypeScript errors | None — `npx tsc --noEmit` clean | ea77aef |

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 001 | Invite flow docs + Civic Trivia Championships integration guide | 2026-02-28 | ed76356 | [001-invite-flow-and-civic-trivia-integration](./quick/001-invite-flow-and-civic-trivia-integration/) |

## Session Continuity

Last session: 2026-03-03T00:00:00Z
Stopped at: Post-release hardening — all blockers resolved
Resume: `/gsd:new-milestone` to start v1.1 planning
