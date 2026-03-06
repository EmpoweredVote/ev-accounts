---
phase: 13-compassv2-backend-compatibility
plan: 01
subsystem: database
tags: [postgresql, migrations, rpc, supabase, soft-delete, inform-schema]

requires:
  - phase: 12-alpha-hardening
    provides: clean compile baseline

provides:
  - Three migration files (026, 027, 028) for inform schema repair and atomic RPCs

affects: [13-02, 13-03, 13-04]

tech-stack:
  added: []
  patterns:
    - SECURITY DEFINER RPC pattern with SET search_path = ''
    - Idempotent migrations with IF NOT EXISTS guards
    - Two-pass validation before writes (atomicity guarantee)
    - Soft-delete via deleted_at column

key-files:
  created:
    - backend/migrations/026_inform_schema_repair_and_candidates.sql
    - backend/migrations/027_rpc_reset_compass_answers.sql
    - backend/migrations/028_rpc_import_compass_calibrations.sql
  modified: []

key-decisions:
  - "Soft-delete via deleted_at column (not hard delete) — preserves data for recovery and audit"
  - "Two-pass validation in import_compass_calibrations — full validation loop completes before any upsert writes begin"
  - "SET search_path = '' on all SECURITY DEFINER functions (prevents search_path injection)"
  - "Migration 026 is a repair migration — all CREATE TABLE/INDEX use IF NOT EXISTS to be safe on DBs with existing inform tables"

duration: 2min
completed: 2026-03-06
---

# Phase 13 Plan 01: Schema Migrations Summary

**Three idempotent SQL migrations that repair the inform schema namespace, add soft-delete and is_candidate columns, and introduce two SECURITY DEFINER RPCs for atomic compass state management.**

## What Was Built

### Migration 026 — inform schema repair + new columns

Repairs the open blocker from STATE.md: migration 015 was recorded as applied but the `inform` schema namespace was never created in the live database. Migration 026 starts with `CREATE SCHEMA IF NOT EXISTS inform` then idempotently recreates all 10 inform tables and all indexes from migration 015 using `IF NOT EXISTS` guards (safe on DBs where those objects already exist).

Net-new additions beyond the migration 015 repair:
- `ALTER TABLE inform.compass_responses ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ` — enables soft-delete for the reset flow
- `ALTER TABLE inform.politicians ADD COLUMN IF NOT EXISTS is_candidate BOOLEAN NOT NULL DEFAULT false` — flags candidates for ZIP-based discovery
- `CREATE INDEX IF NOT EXISTS idx_compass_responses_user_active ON inform.compass_responses(user_id) WHERE deleted_at IS NULL` — partial index for the most common read pattern (active responses per user)

### Migration 027 — reset_compass_answers RPC

`public.reset_compass_answers(p_user_id UUID, p_full_reset BOOLEAN DEFAULT false)`

Atomically resets a user's compass state in a single PL/pgSQL block (implicit transaction):
1. Soft-deletes all active `compass_responses` (sets `deleted_at = now()` where `deleted_at IS NULL`)
2. Clears `selected_topic_ids` on `connected_profiles`
3. Optionally resets `completed_onboarding = false` (when `p_full_reset = true`)

If any UPDATE fails, the exception propagates and all changes are rolled back.

### Migration 028 — import_compass_calibrations RPC

`public.import_compass_calibrations(p_user_id UUID, p_calibrations JSONB, p_set_onboarding_complete BOOLEAN DEFAULT false)`

Accepts a JSONB array of `{topic_id, value, write_in_text?, inverted?}` elements and atomically upserts them into `inform.compass_responses`. Uses two separate FOR loops to guarantee all-or-nothing atomicity:

**Pass 1 (validation only — no writes):** Iterates all elements, validates that each `topic_id` is a valid UUID that exists in `inform.compass_topics`, and that `value` is an integer in range 1..5. Raises `INVALID_CALIBRATION` immediately on the first failure. No rows are written during this pass.

**Pass 2 (upsert — runs only after full validation):** `INSERT ... ON CONFLICT (user_id, topic_id) DO UPDATE` for each element. The `DO UPDATE` clause sets `deleted_at = NULL` to un-soft-delete rows that were previously reset, enabling clean re-import after a reset.

Optionally sets `completed_onboarding = true` on `connected_profiles` (guarded against unnecessary writes when already true).

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| Soft-delete via `deleted_at` (not hard delete) | Preserves response data for recovery, audit, and re-import. A reset then re-import returns the same rows to active state cleanly. |
| Two-pass validation in `import_compass_calibrations` | A single combined validation+upsert loop would allow partial writes before a late-element validation failure. Two passes mean validation is total before any write begins. |
| `SET search_path = ''` on all SECURITY DEFINER functions | Prevents search_path injection attacks — fully-qualified schema references used throughout (`inform.compass_responses`, `connect.connected_profiles`). |
| Migration 026 as repair migration (IF NOT EXISTS throughout) | Must be safe to run on the live DB where the inform tables may or may not exist, since migration 015 state is uncertain. |

## Deviations from Plan

None — plan executed exactly as written.

## Verification Results

- All three SQL files exist in `backend/migrations/`
- Migration 026: 29 occurrences of `IF NOT EXISTS` (tables + indexes); both `ADD COLUMN IF NOT EXISTS` guards present; `idx_compass_responses_user_active` partial index present
- Migration 027: `SECURITY DEFINER` present; `SET search_path = ''` present; `p_full_reset` conditional block present; all three UPDATE statements present
- Migration 028: `SECURITY DEFINER` present; `SET search_path = ''` present; `ON CONFLICT (user_id, topic_id) DO UPDATE` present; `deleted_at = NULL` in DO UPDATE; `INVALID_CALIBRATION` raise present; exactly 2 `FOR elem IN` loops

## Next Phase Readiness

Plans 13-02, 13-03, and 13-04 can proceed. They depend on:
- `deleted_at` on `compass_responses` (026) — used by GET /compass/answers active filter
- `is_candidate` on `politicians` (026) — used by GET /compass/politicians
- `reset_compass_answers` RPC (027) — used by POST /compass/reset
- `import_compass_calibrations` RPC (028) — used by POST /compass/import

All four dependencies are now available after running these migrations against the live database.
