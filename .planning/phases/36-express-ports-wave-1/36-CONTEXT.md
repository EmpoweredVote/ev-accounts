# Phase 36: Express Ports Wave 1 — Treasury and Meetings - Context

**Gathered:** 2026-03-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Build Express routes for Treasury and Meetings data using the Supabase tables migrated in Phase 34. This is a **greenfield build from Supabase**, not a port from the Go server. The Go server's Treasury and Meetings routes are dormant with no active consumers — its response shapes are not a binding contract.

</domain>

<decisions>
## Implementation Decisions

### Go API contract source
- Primary source of truth: Supabase treasury and meetings schemas (already migrated in Phase 34)
- Go server is a secondary historical reference only — not authoritative
- Route discovery via curl against live Go server if accessible, but schema inspection is the real starting point
- Go server status uncertain (may be partially down) — researcher should verify before relying on it
- No frontend apps (Treasury Tracker, Meetings viewer) are confirmed to be consuming Go routes for these features

### URL paths and response shape
- Fresh ev-accounts routes: `/api/treasury/...` and `/api/meetings/...`
- camelCase field names, TypeScript-idiomatic shapes — same conventions as the rest of ev-accounts
- No obligation to match Go's URL paths or field names
- Success criteria in ROADMAP.md should be updated to reflect "Supabase-first design" rather than "parity with Go equivalents"

### Admin auth model
- Treasury writes: `requireAdmin` middleware (global admin access to all records, no creator-scoping)
- Meetings management (create/update/delete): `requireAdmin` middleware
- Meetings user actions (RSVP, agenda items): `requireAuth` with Connected-tier minimum check
- Treasury reads: public (unauthenticated)
- Meetings reads: public (unauthenticated)

### Transition strategy
- Hard cutover — build Express routes, smoke test, done
- No proxy or fallback to Go server needed (dormant, no active consumers)
- Validation: curl smoke test against each route on Render staging (HTTP 200/201/204, no 500s, verify response shape)
- No automated tests required for phase completion

### Claude's Discretion
- Exact route inventory (researcher determines from Supabase schema what routes make sense)
- Response shape design (follow ev-accounts patterns; infer from table structures)
- Any pagination or filtering patterns on list routes

</decisions>

<specifics>
## Specific Ideas

- The data is already in Supabase — Phase 34 migrated all treasury and meetings tables. No data migration work needed, only route implementation.
- Researcher should inspect `treasury.*` and `meetings.*` schemas via Supabase MCP to enumerate tables and determine sensible route inventory before planning.

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed within phase scope

</deferred>

---

*Phase: 36-express-ports-wave-1*
*Context gathered: 2026-03-19*
