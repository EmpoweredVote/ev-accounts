---
phase: 41-vq-and-trivia-migration
plan: 01
subsystem: database
tags: [postgres, rls, migration, validation_quests, trivia, schema-inspection]

# Dependency graph
requires:
  - phase: 34-schema-migration
    provides: "EV-Backend schemas (including validation_quests and trivia) already exist in ev-accounts Supabase project"
  - phase: 35-location-schema-rpcs
    provides: "essentials.politicians table and public.politician_id_bridge already in ev-accounts"
provides:
  - "Complete table inventory for validation_quests (13 tables) and trivia (9 tables)"
  - "Exact baseline row counts for post-restore verification"
  - "RLS category assignments for all 22 tables (owner-read vs public-read)"
  - "Trivia FK gap analysis: ZERO gaps — trivia has no FK references to essentials.politicians"
  - "Trivia external FK analysis: only public.users references (safe)"
  - "VQ constraint analysis: no cross-schema FK constraints — fully self-contained"
  - "Triggers: zero triggers in either schema"
affects:
  - 41-02-restore
  - 41-03-rls
  - 41-04-cutover

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pre-flight inspection: baseline row counts captured before migration for post-restore verification"

key-files:
  created:
    - ".planning/phases/41-vq-and-trivia-migration/41-01-SUMMARY.md"
  modified: []

key-decisions:
  - "Trivia has ZERO politician FK columns — the assumption in PLATFORM-CONSOLIDATION.md about FK reconciliation against essentials.politicians does not apply to this migration"
  - "Trivia candidates stored as JSONB in election_races.candidates — no FK to essentials.politicians"
  - "VQ is fully self-contained with no cross-schema FK constraints — no restore ordering constraint"
  - "All trivia external FKs reference public.users — this table exists in ev-accounts already"
  - "Trivia connection model TBD — awaiting user confirmation (checkpoint:decision)"

patterns-established:
  - "Owner-read RLS pattern: tables with user_id column get policy allowing auth.uid() = user_id"
  - "Public-read RLS pattern: tables without user_id get public SELECT + service_role full access"

# Metrics
duration: 15min
completed: 2026-03-23
---

# Phase 41 Plan 01: Pre-flight Inspection Summary

**Complete table inventory for validation_quests (13 tables) and trivia (9 tables) with baseline row counts, RLS category assignments, zero trivia politician FK gaps, and no cross-schema FK blockers found**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-03-23T06:00:07Z
- **Completed:** 2026-03-23T06:15:00Z
- **Tasks:** 1 of 2 (stopped at checkpoint:decision)
- **Files modified:** 1

## Pre-Flight Inspection Results

### Table Inventory

Both schemas reside in the EV-Backend Supabase project (`kxsdzaojfaibhuzmclfq`) as confirmed. This is the same project as ev-accounts. No separate VQ Supabase project was needed.

**Note on PLATFORM-CONSOLIDATION.md estimates:** The estimate was 14 tables for validation_quests; actual count is **13 tables**. Trivia matches the estimate of **9 tables** exactly.

---

### validation_quests Schema — 13 Tables

| Table | Row Count | User ID Column | RLS Category |
|-------|-----------|----------------|--------------|
| `admin_override_log` | 0 | none | service_role only (admin audit log) |
| `ai_agent_credentials` | 0 | none | service_role only (credentials — never user-readable) |
| `consensus_records` | 2 | none | public-read (aggregate quest data) |
| `gem_reward_events` | 2 | `user_id` (uuid) | owner-read |
| `quest_assignments` | 0 | `user_id` (uuid) | owner-read |
| `quest_contests` | 1 | none | public-read (contest metadata) |
| `user_notification_preferences` | 1 | `user_id` (uuid, PK) | owner-read |
| `user_notifications` | 2 | `user_id` (uuid) | owner-read |
| `user_quest_assignments` | 0 | `user_id` (uuid) | owner-read |
| `user_veracity_profiles` | 4 | `user_id` (uuid, PK) | owner-read |
| `veracity_event_logs` | 11 | `user_id` (uuid) | owner-read |
| `verification_quests` | 193 | `created_by` (uuid) | public-read (quest catalog) |
| `verification_submissions` | 9 | `user_id` (uuid) | owner-read |

**Total VQ rows:** 225 across 13 tables

**Baseline row counts (for post-restore verification):**
- Non-empty tables: consensus_records=2, gem_reward_events=2, quest_contests=1, user_notification_preferences=1, user_notifications=2, user_veracity_profiles=4, veracity_event_logs=11, verification_quests=193, verification_submissions=9
- Empty tables (still must restore with 0 rows): admin_override_log, ai_agent_credentials, quest_assignments, user_quest_assignments

---

### trivia Schema — 9 Tables

| Table | Row Count | User ID Column | RLS Category |
|-------|-----------|----------------|--------------|
| `collection_questions` | 3,245 | none | public-read (game content M2M) |
| `collection_topics` | 225 | none | public-read (game content M2M) |
| `collections` | 21 | none | public-read (game content) |
| `election_races` | 1 | none | public-read (race metadata) |
| `player_prefs` | 0 | `user_id` (uuid) | owner-read |
| `player_stats` | 3 | `user_id` (uuid) | owner-read |
| `question_flags` | 5 | `user_id` (uuid) | owner-read (user's own flags) |
| `questions` | 3,245 | none | public-read (game content) |
| `topics` | 92 | none | public-read (game content) |

**Total trivia rows:** 6,837 across 9 tables (bulk is questions content)

---

### RLS Category Summary

| Category | Tables |
|----------|--------|
| **owner-read** (user_id = auth.uid()) | gem_reward_events, quest_assignments, user_notification_preferences, user_notifications, user_quest_assignments, user_veracity_profiles, veracity_event_logs, verification_submissions, player_prefs, player_stats, question_flags |
| **public-read** (SELECT for all, DML via service_role) | consensus_records, quest_contests, verification_quests, collection_questions, collection_topics, collections, election_races, questions, topics |
| **service_role only** (no user reads) | admin_override_log, ai_agent_credentials |

---

### Trivia FK Gap Analysis

**Finding: ZERO politician FK columns in trivia schema.**

The PLATFORM-CONSOLIDATION.md assumption that trivia has FK references to politicians requiring reconciliation against `essentials.politicians` is **not borne out by the actual schema**. Inspection results:

- No column in any trivia table matches `%politician%` (exact query run)
- `trivia.questions` has an `election_race_id` column (integer FK), but it references `trivia.election_races` — a self-contained table within the trivia schema
- `trivia.election_races` stores candidate data as a **JSONB column** (`candidates jsonb NOT NULL`), not as FK references to politicians
- `public.politician_id_bridge` (Phase 35) is **not needed** for this migration

**FK gap count: 0 (zero)** — No reconciliation work required.

---

### Trivia External FK Constraints (Restore Blockers)

Three trivia tables have FK constraints referencing `public.users`:

| Table | Column | References |
|-------|--------|-----------|
| `trivia.player_prefs` | `user_id` | `public.users(id)` |
| `trivia.player_stats` | `user_id` | `public.users(id)` |
| `trivia.question_flags` | `user_id` | `public.users(id)` |

**Impact:** `public.users` exists in ev-accounts already (it's the auth users table). These FKs will resolve correctly after restore as long as the UUIDs in the 3 trivia rows (player_stats=3, question_flags=5, player_prefs=0) match users in ev-accounts' `public.users`. This is expected since it's the same platform.

**Restore ordering:** Restore trivia AFTER confirming public.users data is present (standard — public.users is the auth layer, always present).

---

### VQ External FK Constraints

**Finding: ZERO cross-schema FK constraints in validation_quests.**

VQ has only primary key constraints. No FKs to `public.users`, `essentials.*`, `connect.*`, or any other schema. VQ is fully self-contained — can be restored independently with no ordering constraint.

---

### Triggers

**Finding: ZERO triggers in either schema.**

No trigger definitions exist in `validation_quests` or `trivia`. Schema restoration will not need to handle trigger ordering or trigger function dependencies.

---

### Functions/RPC Check

Not queried in this inspection — VQ calls ev-accounts API (HTTP) for its confirmation flow; the `connect.confirm_vq_stance` RPC lives in the connect schema (ev-accounts), not in validation_quests. No VQ-internal functions expected.

---

## Decisions Made

- **Trivia politician FK reconciliation: not needed** — The anticipated FK gap analysis is moot. Trivia stores politician/candidate data as JSONB in `election_races.candidates`, not as FK references to any external politician table. Plans 02-04 should omit the FK reconciliation step.
- **Trivia connection model: TBD** — Awaiting user decision at checkpoint (see below). The schema inspection cannot determine this; it requires knowing Trivia's backend architecture.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed as specified.

### Findings That Differ from Plan Assumptions

**1. Trivia has no politician FK columns**

- **Expected:** Plan specified query for `%politician%` columns and FK gap analysis against `essentials.politicians`
- **Actual:** Zero matches. Trivia uses JSONB for candidate data in `election_races.candidates`
- **Impact on downstream plans:** Remove trivia FK reconciliation step from Plan 02. No insert/null strategy needed.

**2. VQ table count is 13, not 14**

- **Expected:** PLATFORM-CONSOLIDATION.md estimated 14 tables for validation_quests
- **Actual:** 13 tables found
- **Impact:** Minor — baseline is now exact. Plan 02 restore verification should expect 13 tables.

## Issues Encountered

None — all queries executed cleanly.

## Next Phase Readiness

- **Ready for Plan 02 (Restore):** Full table inventory, row counts, and FK analysis in hand. Restore can proceed once Trivia connection model is confirmed.
- **Blockers:** Trivia connection model decision required before Plans 02-04 can be finalized. See checkpoint below.

---

## CHECKPOINT: Decision Required

### Trivia Connection Model

**Background:**
VQ's connection model is established — it uses `DATABASE_URL` pointing directly at the Supabase Postgres database (port 5432) for its own schema writes. After migration, VQ's `DATABASE_URL` will point at ev-accounts with a `vq_service` role.

**The open question is Trivia's connection model:**

1. **Does Civic Trivia connect directly via `DATABASE_URL`?**
   - If YES: Plan 02 must create a `trivia_service` Postgres role (same pattern as `vq_service`). Plan 04 must update Trivia's `DATABASE_URL` env var on Render.
   - If NO (API-only): No `trivia_service` role needed. Trivia schema just needs RLS for ev-accounts service_role access. Plan 04 only needs to update an API key (if any).

**Options:**

| Option | Description | Plan Impact |
|--------|-------------|-------------|
| `trivia-direct-db` | Trivia connects via DATABASE_URL directly to Postgres | Plan 02 creates `trivia_service` role; Plan 04 updates DATABASE_URL on Render |
| `trivia-api-only` | Trivia calls ev-accounts API only (no direct DB connection) | No trivia_service role; trivia schema RLS serves service_role only |

**My read:** Given that Trivia is a game app serving questions to players, it likely reads from the trivia schema directly (high-frequency reads benefit from direct DB connection vs HTTP round-trips). I'd guess `trivia-direct-db`, but this is architectural knowledge about Trivia's backend that only you have.

### Resume Signal

Tell me:
1. Does Civic Trivia connect directly via DATABASE_URL? (yes = trivia-direct-db, no = trivia-api-only)
2. Note: trivia politician FK reconciliation is NOT needed — the schema uses JSONB for candidate data, not politician UUIDs.

---
*Phase: 41-vq-and-trivia-migration*
*Completed: 2026-03-23*
