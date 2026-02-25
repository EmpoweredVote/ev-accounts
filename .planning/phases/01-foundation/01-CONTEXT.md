# Phase 1: Foundation - Context

**Gathered:** 2026-02-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Define the complete database layer before any application code runs: all 4 schemas (public, connect, empower, inform), all tables, all RLS policies, all atomic RPC functions. Also includes server bootstrap — dual Supabase client pattern, JWT middleware, Zod env validation, and health endpoint.

Routes, user flows, and feature endpoints are explicitly out of scope. Phase 1 delivers a tested, RLS-enforced foundation that all subsequent phases build on.

</domain>

<decisions>
## Implementation Decisions

### Account deletion policy
- **Soft delete** — `deleted_at` timestamp on `public.users`, excluded from queries
- Deleted user's invite-chain position is **preserved** — they remain in the tree for Tolerance Rating accountability
- Deletion is **admin-only for Alpha** — no self-service DELETE endpoint in Phase 2
- Handling of child records (connected_profiles, empowered_profiles) on deletion: Claude's discretion

### account_standing enum
- Values: `('active', 'suspended', 'quarantined')` — include all three now; enum alterations on populated tables require new migrations
- Both `suspended` and `quarantined` have the **same lockout level** — semantic distinction (reason/origin), not behavioral
- Enforcement: **RLS + JWT middleware both** — defense in depth; RLS policies check standing, middleware also checks before routing

### inform schema scope
- Phase 1 creates the **`inform` schema namespace only** — no tables
- Compass tables (topics, stances, responses, change_history) are deferred to Phase 4
- Context: the compass codebase already exists on Git and shares the same Supabase project — Phase 4 will adapt and connect it

### RLS visibility design
- **connected_profiles**: visible to any authenticated user — tier status (existence of record) is public; sensitive fields (tolerance_rating, legal_name) remain blocked
- **empowered_profiles**: anonymous users can read public-facing fields (slug, candidate page metadata) — this supports Phase 8 (public candidate pages)
- **public.users**: column-level security — non-owners see `display_name`, avatar, and tier-derived fields; NOT email, `account_standing`, `created_at`, or internal fields
- `tolerance_rating` and `legal_name` blocked at **both** RLS layer and serialization layer (tests must assert absence, not just null)

### Claude's Discretion
- Exact access behavior for `suspended` and `quarantined` accounts (full lockout recommended — same treatment)
- Child record handling on soft-delete (cascade `deleted_at` vs. keep records)
- Migration structure (one migration per schema, or logical groupings)
- RLS predicate implementation details (functions vs. inline checks)

</decisions>

<specifics>
## Specific Ideas

- Phase 4 research task: verify whether the existing compass schema already references `auth.users` or `public.users` as its foreign key. If not, Phase 4 planning must include an adapter/migration to link compass records to this account system.
- The broader platform philosophy is "anonymous users can witness but not participate" (Symposiums, Awareness Exchange, etc.) — this governs future feature repos, not Phase 1 tables directly. Anon access in Phase 1 is limited to public empowered_profiles fields.

</specifics>

<deferred>
## Deferred Ideas

- Platform-wide anonymous read policy ("witness Symposiums, watch Awareness Exchange but can't vote/invest") — applies to future feature repos (Symposiums, Awareness Exchange), not this account infra repo
- `quarantined` state behavioral distinction from `suspended` — deferred to Communal Council feature repo as originally planned

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-02-24*
