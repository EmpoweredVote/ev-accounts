# Phase 9: XP Schema & Core - Context

**Gathered:** 2026-03-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Create the `xp_transactions` ledger table, add `total_xp`/`current_level` columns to `connected_profiles`, enforce RLS, and implement the `award_xp` RPC and `calculate_level` SQL function. No HTTP layer — that is Phase 10. This is the infrastructure every upstream phase depends on.

</domain>

<decisions>
## Implementation Decisions

### XP product intent
- XP is a broad positive engagement metric — it just keeps going up (Overwatch/LoL model). No ceiling, no gating by default.
- XP is one of several progression mechanics. Others (gems, veracity rating, fallacy-finder rating) are separate systems. Actions can award multiple progression types simultaneously (e.g., a Validation Quest submission awards both XP and veracity rating).
- Sources will be numerous — every significant platform action across many feature repos can award XP.

### xp_transactions schema
- `source TEXT NOT NULL` — freeform string, not a Postgres enum or CHECK constraint. New source types must not require a DB migration. Validation lives at the API layer (Phase 10).
- `amount INT NOT NULL CHECK (amount > 0)` — XP is always positive in v1.1. Deductions/penalties are out of scope.
- `metadata JSONB NULL` — required for admin audit trail. Admin grants must populate `{ "admin_id": "...", "reason": "..." }`. Feature sources may include contextual data (e.g., `{ "quest_id": "...", "quest_name": "..." }`).
- `idempotency_key TEXT NOT NULL UNIQUE` — enforced at DB layer.

### Source naming convention
- Pattern: `{feature}_{action}` — e.g., `compass_calibrate`, `fallacy_finder_review`, `validation_quest_submit`, `invite_accepted`, `admin_grant`.
- Convention is enforced in Phase 10's source enum/validation list, not in the DB schema.

### connected_profiles additions
- Add `total_xp BIGINT NOT NULL DEFAULT 0` and `current_level INT NOT NULL DEFAULT 0`.
- No additional columns — `last_xp_awarded_at` and `level_updated_at` are derivable from the ledger.

### award_xp RPC
- Input params: `p_user_id UUID, p_source TEXT, p_amount INT, p_idempotency_key TEXT, p_metadata JSONB DEFAULT NULL`
- No separate `p_awarded_by` param — admin identity goes in `p_metadata`.
- Returns the full XP profile: `total_xp, current_level, xp_in_level, xp_to_next_level` plus the created transaction row — so Phase 10 can respond without a second query.
- On idempotent replay (same `idempotency_key`): return the original transaction row, same shape as success. Silent no-op, not an error.
- Mirrors the gem ledger pattern: advisory lock, append-only insert, denormalized balance update, all in one transaction.

### calculate_level function
- Standalone callable Postgres function: `calculate_level(total_xp BIGINT)` returning `(level INT, xp_in_level INT, xp_to_next_level INT)`.
- Must be callable independently — Phase 10 needs level data on reads (e.g., `GET /account/me`) without calling `award_xp`.
- `award_xp` calls this function internally to update `current_level` on `connected_profiles`.
- Level thresholds (already locked): 2k XP × 3 levels, 3k × 6 levels, 4k × 20 levels, 5k per level thereafter.

### RLS policies
- Connected users: SELECT own `xp_transactions` rows only.
- Unauthenticated: zero rows.
- INSERT: blocked via RLS — only the `award_xp` RPC (SECURITY DEFINER) may write rows.

### Claude's Discretion
- Exact advisory lock implementation detail
- Index strategy on `xp_transactions` (e.g., `(user_id, created_at)`)
- SQL function structure and CTEs inside `award_xp`
- Temp/intermediate variable naming in SQL

</decisions>

<specifics>
## Specific Ideas

- "XP is like Overwatch/League of Legends — the number just keeps going up. That's fine."
- Admin tools need great memory — every admin XP action must be auditable. The `metadata` column + append-only ledger is the audit trail.
- Actions can award XP AND other progression types simultaneously. The XP ledger is independent of the other systems.

</specifics>

<deferred>
## Deferred Ideas

- Deductions / XP penalties — out of scope for v1.1, could be its own phase
- XP leaderboards or public rankings — future feature
- Scheduled/bulk XP awards (e.g., for retroactive grants) — future admin tooling
- Per-feature XP caps (e.g., max 100 XP/day from `daily_login`) — rate limiting is a Phase 10 concern if needed

</deferred>

---

*Phase: 09-xp-schema-core*
*Context gathered: 2026-03-04*
