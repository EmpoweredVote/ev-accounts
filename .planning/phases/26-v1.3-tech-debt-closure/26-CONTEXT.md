# Phase 26: v1.3 Tech Debt Closure - Context

**Gathered:** 2026-03-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix four specific issues surfaced in the v1.3 audit: migration idempotency (031/032), PATCH `/me` field parity with GET `/me`, legacy `gem_balance` removal from `database.types.ts`, and REQUIREMENTS.md traceability accuracy. No new features — pure cleanup.

</domain>

<decisions>
## Implementation Decisions

### Migration edit strategy
- Edit migrations 031 and 032 **in-place** — rewrite the broken lines directly in the existing files
- Production already applied these migrations and won't re-run them; in-place edits fix fresh deploys and `supabase db reset` without adding corrective migration noise
- Migration 031: replace `CREATE POLICY IF NOT EXISTS` with idempotent DO block checking `pg_policies`
- Migration 032: replace bare `geometry` with `public.geometry` in DECLARE blocks

### PATCH /me response shape
- Return the **full GET `/me` field set** after a successful PATCH — identical structure including `location_consent`
- PATCH and GET `/me` must return the same shape; clients never need a follow-up GET after a PATCH

### Types update method
- **Surgical manual edit** — remove only `gem_balance` from Row/Insert/Update shapes in `database.types.ts`
- Do not run `supabase gen types` regeneration; preserve existing manual fixes (e.g., `location_consent` added in Phase 20)

### REQUIREMENTS.md scope
- Minimum targeted update: mark GEM-01/02/03 complete, add HUB-01 through HUB-04 with Phase 24 reference and Complete status
- No full audit pass — scope is limited to the four items in the Phase 26 success criteria

### Claude's Discretion
- Exact DO block structure for the `pg_policies` check in migration 031
- Field ordering within the PATCH `/me` response object

</decisions>

<specifics>
## Specific Ideas

- All four fixes are surgical — no refactoring, no cleanup beyond the four named items
- Migration in-place edits are safe because production already applied these and idempotency checks prevent re-application

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 26-v1.3-tech-debt-closure*
*Context gathered: 2026-03-15*
