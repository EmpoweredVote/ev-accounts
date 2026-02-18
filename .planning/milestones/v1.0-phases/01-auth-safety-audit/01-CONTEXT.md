# Phase 1: Auth Safety Audit - Context

**Gathered:** 2026-02-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Verify and document the existing auth flow before any session/cookie changes ship. Deliverables: confirm login/logout/session persistence works, document cookie configuration with production migration notes, and categorize all Chi routes by auth level. This establishes the contract Phase 2 builds on.

</domain>

<decisions>
## Implementation Decisions

### Route manifest design
- Three auth levels: public, guest-ok, auth-required — with an admin flag annotation on auth-required routes that need elevated privileges
- Manifest includes both views: primary grouping by module (auth, compass, essentials, etc.) with a summary table grouped by auth level at the top
- Manifest should include a Phase 2 handoff section explicitly listing what Phase 2 can rely on

### Claude's Discretion
- Level of detail per route entry (path + method + level minimum; handler names if useful)
- Whether to flag Phase 2 mismatches (routes that are auth-required now but should become guest-ok)

### Confirmed safe bar
- Automated tests that verify auth behavior programmatically — not just code review and docs
- Tests should confirm: login works, session persists across requests, logout clears session, tab reload preserves login state

### Claude's Discretion
- Testing approach: integration tests vs handler unit tests vs both — pick what gives the most confidence
- Whether to surface security concerns found during audit (CSRF, session fixation, etc.) as recommendations or stay strictly behavioral
- Test database strategy — isolated Supabase, in-memory, or whatever makes tests reliable and easy to run

### Domain migration notes
- No timeline for domain migration — document what needs to change, but treat as a future task
- Hosting may consolidate (currently Netlify + Render split) — notes should be hosting-agnostic where possible

### Claude's Discretion
- Whether to scope migration notes beyond cookie config (CORS origins, frontend env vars, DNS)
- Whether to include a rollback plan for cookie config changes

### Audit deliverable format
- Dual location: planning summary in .planning/, detailed auth docs in the codebase at EV-Backend/docs/
- Codebase docs go in a new EV-Backend/docs/ directory
- Include a "Phase 2 handoff" section that explicitly lists what Phase 2 can assume is true

### Claude's Discretion
- Whether route manifest is a standalone file or a section within the auth audit doc

</decisions>

<specifics>
## Specific Ideas

- The route manifest is the key contract for Phase 2 (Guest-First Auth) — it needs to clearly show which routes currently require auth so Phase 2 knows exactly what to change
- Automated tests serve as the "proof" that auth works — not just documentation saying it does
- Domain migration notes should acknowledge that hosting might consolidate, so don't hardcode assumptions about Netlify/Render split

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-auth-safety-audit*
*Context gathered: 2026-02-17*
