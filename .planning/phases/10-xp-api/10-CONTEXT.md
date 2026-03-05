# Phase 10: XP API - Context

**Gathered:** 2026-03-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Express API routes for reading and awarding XP. Feature repos call a service-key-authenticated award endpoint; authenticated users can read their own XP history; unauthenticated callers can look up a user's public XP profile; and `GET /account/me` is extended with an `xp` object. Idempotency is enforced at the route layer (backed by the Phase 9 RPC). No new ledger schema — this phase is pure API surface over what Phase 9 built.

</domain>

<decisions>
## Implementation Decisions

### Source validation
- Valid source types (initial set): `validation_quest_completion`, `civic_trivia_championship_score`, `admin_gift`
- Source enum lives in **both** TypeScript (validated first, returns 422 on unknown source) and as a Postgres enum (DB backstop for any slip-through)
- Per-source authorization is enforced: each service key maps to a set of permitted source types. A valid key using a source it isn't authorized for → 422 (same as unknown source)

### Service key auth
- **One key per service** — each feature repo has its own `X-Service-Key`
- Keys stored as **environment variables**: `QUEST_SERVICE_KEY`, `TRIVIA_SERVICE_KEY`, `ADMIN_SERVICE_KEY`
- Permitted source types per key is a **hardcoded mapping in code** (e.g., `{ QUEST_SERVICE_KEY: ['validation_quest_completion'], TRIVIA_SERVICE_KEY: ['civic_trivia_championship_score'], ADMIN_SERVICE_KEY: ['admin_gift'] }`)
- No DB or Redis lookup at request time — env var check is sufficient for Alpha

### POST /api/xp/award response
- Success (non-duplicate): full transaction + level state
  ```json
  { "transaction_id": "...", "user_id": "...", "source": "...", "amount": 100,
    "created_at": "...", "level": 3, "total_xp": 7200,
    "xp_in_level": 200, "xp_to_next_level": 3800, "is_duplicate": false }
  ```
- Duplicate (same idempotency key): **200 OK** with original transaction data and `is_duplicate: true` — no error, no second ledger row

### GET /api/xp/me/history response
- Paginated — supports `limit` + `offset` query params
- Each entry: `{ id, source, amount, metadata, created_at }` — ID included for frontend reference
- Unauthenticated → 401

### GET /api/xp/:userId response (public)
- Returns `{ level, total_xp, xp_in_level, xp_to_next_level }` — the extra fields enable a progress bar on public profile without exposing the full ledger

### Claude's Discretion
- HTTP code for missing/invalid `X-Service-Key` — match the existing auth middleware pattern in the codebase
- HTTP code for non-existent or non-Connected `userId` on award — likely 404 but check existing route conventions
- Error response body shape — match the existing error shape used in other routes (probably `{ error: '...' }`)
- Pagination defaults (e.g., default limit, max limit) — pick reasonable values

</decisions>

<specifics>
## Specific Ideas

- The service-key → permitted-sources mapping is hardcoded; when a new service needs to award XP, a developer adds the env var and updates the mapping in one place
- Idempotency behavior on duplicate mirrors the Phase 9 RPC: return the **current** profile state (not the historical state at the time of the original award)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 10-xp-api*
*Context gathered: 2026-03-04*
