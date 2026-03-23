---
phase: 41-vq-and-trivia-migration
plan: "03"
subsystem: database
tags: [postgres, rls, row-level-security, supabase, validation_quests, trivia]

requires:
  - phase: 41-02
    provides: trivia_service Postgres role with BYPASSRLS; leaderboard endpoint live
  - phase: 41-01
    provides: confirmed table inventory for both schemas; RLS category assignments

provides:
  - RLS enabled on all 22 tables (13 validation_quests + 9 trivia)
  - 5 new policies added: 3 missing (gem_reward_events, user_quest_assignments, quest_contests) + 2 anon-access gaps fixed
  - Schema USAGE + SELECT grants for anon/authenticated on both schemas
  - admin_override_log and ai_agent_credentials confirmed as deny-all (0 policies)

affects:
  - 41-04: cutover verification; RLS complete is a prerequisite

tech-stack:
  added: []
  patterns:
    - "RLS pre-existing pattern: VQ and trivia schemas came from ev-backend with RLS already on; migration adds only missing/incorrect policies"
    - "Anon-access split pattern: for tables with pre-existing authenticated-only SELECT, add a separate anon SELECT policy rather than replacing"
    - "ENABLE ROW LEVEL SECURITY is idempotent: safe to include in migration even when already enabled"

key-files:
  created:
    - supabase/migrations/20260323000052_phase41_vq_trivia_rls.sql

key-decisions:
  - "All 11 owner-read tables have user_id uuid — no cast needed; pattern (SELECT auth.uid()) = user_id"
  - "consensus_records and verification_quests had authenticated-only policies; plan category = public-read; added separate anon SELECT policies to complement existing"
  - "trivia owner-read tables have additional INSERT/UPDATE policies from original schema — retained (correct, enables VQ JS client DML)"
  - "applyMigrations.ts NOT updated — that script covers only old-format 026-038 migrations in backend/migrations/; new-format migrations in supabase/migrations/ are applied directly via MCP"

patterns-established:
  - "Pre-flight column type check before writing RLS migration: avoids cast errors (uuid vs text)"
  - "Pre-flight policy existence check: prevents CREATE POLICY errors on already-configured schemas"

duration: 8min
completed: 2026-03-23
---

# Phase 41 Plan 03: VQ and Trivia RLS Summary

**RLS fully enforced on all 22 validation_quests and trivia tables: 5 missing/misconfigured policies added, schema grants applied, anon blocked from owner-read rows**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-23T07:11:50Z
- **Completed:** 2026-03-23T07:19:50Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- All 22 tables confirmed `rowsecurity = true` (pre-existing from original schema migrations)
- 5 new policies applied: gem_reward_events (owner SELECT), user_quest_assignments (owner SELECT), quest_contests (public read), consensus_records (anon read), verification_quests (anon read active)
- Schema USAGE + SELECT grants applied for anon, authenticated, and service_role on both schemas
- admin_override_log and ai_agent_credentials: 0 policies — deny all for non-BYPASSRLS roles confirmed

## Full Table Inventory with Policy State

**validation_quests — owner-read (8 tables):**

| Table | SELECT Policy | Additional |
|-------|---------------|------------|
| gem_reward_events | owner SELECT (NEW) | — |
| quest_assignments | owner SELECT (pre-existing) | — |
| user_notification_preferences | owner SELECT (pre-existing) | ALL for authenticated (pre-existing) |
| user_notifications | owner SELECT (pre-existing) | — |
| user_quest_assignments | owner SELECT (NEW) | — |
| user_veracity_profiles | owner SELECT (pre-existing) | — |
| veracity_event_logs | owner SELECT (pre-existing) | — |
| verification_submissions | owner SELECT (pre-existing) | INSERT authenticated (pre-existing) |

**validation_quests — public-read (3 tables):**

| Table | Policy |
|-------|--------|
| consensus_records | authenticated SELECT (pre-existing) + anon SELECT (NEW) |
| quest_contests | public read for anon, authenticated (NEW) |
| verification_quests | authenticated SELECT active (pre-existing) + anon SELECT active (NEW) |

**validation_quests — service_role only (2 tables):**

| Table | Policies |
|-------|----------|
| admin_override_log | 0 policies — BYPASSRLS only |
| ai_agent_credentials | 0 policies — BYPASSRLS only |

**trivia — public-read (6 tables):**

| Table | Policy |
|-------|--------|
| collection_questions | public read (pre-existing) |
| collection_topics | public read (pre-existing) |
| collections | public read (pre-existing) |
| election_races | public read (pre-existing) |
| questions | public read (pre-existing) |
| topics | public read (pre-existing) |

**trivia — owner-read (3 tables):**

| Table | SELECT Policy | Additional |
|-------|---------------|------------|
| player_prefs | owner SELECT (pre-existing) | INSERT + UPDATE authenticated (pre-existing) |
| player_stats | owner SELECT (pre-existing) | INSERT + UPDATE authenticated (pre-existing) |
| question_flags | owner SELECT (pre-existing) | INSERT authenticated (pre-existing) |

## Policy Counts (Final)

- validation_quests: 15 policies (8 owner-read SELECT + 3 public-read + 2 extra DML + 2 anon added)
- trivia: 14 policies (6 public-read SELECT + 3 owner-read SELECT + 5 DML from original schema)
- Total new policies added this plan: 5

Note: Plan targeted 11 VQ + 9 trivia = 20 policies. Actual counts are higher because original schema migrations already included INSERT/UPDATE DML policies on trivia owner tables and VQ user tables. These are correct and desirable — they enable the VQ Supabase JS client to write data directly.

## Task Commits

1. **Task 1: Write and apply RLS migration** - `30cee63` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `supabase/migrations/20260323000052_phase41_vq_trivia_rls.sql` — RLS ENABLE (idempotent) + 5 new policies + schema grants for validation_quests and trivia

## Decisions Made

1. **user_id column type confirmed uuid** — pre-flight query on all 11 owner-read tables returned `data_type = 'uuid'` for all. Pattern `(SELECT auth.uid()) = user_id` used; no cast required (Phase 34 compass `::uuid` cast pattern not needed here).

2. **Tables pre-configured with RLS** — all 22 tables already had `rowsecurity = true` from the original ev-backend schema migrations. The migration file is still written and applied (idempotent ENABLE ROW LEVEL SECURITY statements) to serve as the canonical record of what was verified and added.

3. **Anon-access split pattern** — consensus_records and verification_quests had pre-existing authenticated-only SELECT policies. Rather than replacing them, added separate anon SELECT policies. Postgres policy OR semantics: a user satisfying either policy gets access. Both approaches yield identical access behavior; split is cleaner than DROP + recreate.

4. **verification_quests anon policy scoped to active** — pre-existing policy filters `status = 'active'`. New anon policy matches that filter rather than using `USING (true)`. Keeps anon access consistent with authenticated access (no drafts/archived quests visible to unauthenticated users).

5. **applyMigrations.ts not updated** — that script covers only old-format migrations (026-038) in `backend/migrations/`. New-format `supabase/migrations/` files are applied directly via MCP management API. Adding to applyMigrations.ts would be incorrect.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Pre-existing policies were authenticated-only on public-read tables**

- **Found during:** Task 1 (pre-flight policy existence check)
- **Issue:** Plan specified consensus_records and verification_quests as public-read (anon + authenticated). Pre-existing policies granted only `TO authenticated`. Anon users would have been blocked from public quest catalog content.
- **Fix:** Added separate anon SELECT policies for both tables. consensus_records: `USING (true)`. verification_quests: `USING (status = 'active'::validation_quests.quest_status)` to match existing scope.
- **Files modified:** supabase/migrations/20260323000052_phase41_vq_trivia_rls.sql
- **Verification:** Policy list confirms both anon and authenticated entries on both tables.
- **Committed in:** 30cee63

---

**Total deviations:** 1 auto-fixed (bug: wrong role scope on 2 public-read tables)
**Impact on plan:** Required for correctness — anon access to the public quest catalog was the stated goal. No scope creep.

## Issues Encountered

- **All 22 tables already had RLS enabled** — the original ev-backend schema migrations had already run `ENABLE ROW LEVEL SECURITY`. This is informational, not a problem. Migration handles it idempotently.
- **Most VQ/trivia policies already existed** — only 3 were entirely missing (gem_reward_events, user_quest_assignments, quest_contests). 2 had wrong role scope (anon exclusion). 5 total policies added.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- RLS is fully enforced on all 22 validation_quests and trivia tables
- VQ Supabase JS client: anon/authenticated reads and authenticated writes are governed by policies (correct behavior confirmed)
- trivia_service BYPASSRLS: unaffected by RLS policies; CTC writes proceed normally
- ev-accounts service_role BYPASSRLS: unaffected
- Plan 04 (cutover verification) is unblocked — all RLS prerequisites satisfied

---
*Phase: 41-vq-and-trivia-migration*
*Completed: 2026-03-23*
