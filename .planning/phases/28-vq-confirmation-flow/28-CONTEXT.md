# Phase 28: VQ Confirmation Flow - Context

**Gathered:** 2026-03-15
**Status:** Ready for planning

<domain>
## Phase Boundary

A single service-key-authenticated POST endpoint (`/api/vq/confirm-stance`) that resolves a VQ question — awarding Red Gems to correct answerers, adjusting Verification Ratings in both directions, writing the confirmed politician stance to `inform.politician_answers`, and replaying idempotently on duplicate `idempotency_key`. No UI. No user-facing changes. Backend contract only.

</domain>

<decisions>
## Implementation Decisions

### Response shape
- Return a structured summary with per-user breakdown:
  `{ question_id, correct_count, incorrect_count, users: [{ user_id, result: 'correct'|'incorrect', gems_awarded, rating_delta, new_rating }] }`
- On replay (duplicate `idempotency_key`), return the identical original result with `replayed: true` added — caller can distinguish replay from fresh without extra logic

### Invalid input handling
- Unknown user IDs (not found in `connected_profiles`): skip and continue — don't fail the batch. Include unresolved IDs in `unresolved_users: []` in the response
- Invalid `question_id` (no matching politician/topic pair): hard fail with 404 — nothing should be written. A bad question_id is a VQ integration bug, not a runtime condition
- Structural errors (missing required fields, malformed payload): standard 400/422

### Rating boundary behavior
- **Floor (rating hits 0):** Set `vq_hold_until = now + 30 days`. Always overwrite — reset the clock regardless of whether an existing hold is active. Predictable behavior; effectively penalizes repeated failures.
- **User already on hold (rating = 0, another incorrect answer):** Overwrite `vq_hold_until` to `now + 30 days`. Rating stays at 0 (can't go below floor).
- **Ceiling (rating = 150, +3 would overflow):** Cap at 150 silently. Response shows `rating_delta: 0, new_rating: 150`. No error, no flag.

### Confirmed stance write semantics
- **Upsert** — overwrite `inform.politician_answers` on every non-replay call. VQ is the authoritative source for confirmed stances.
- If a question is re-confirmed (new `idempotency_key`, same `question_id` with a different answer): full flow runs — stance is overwritten AND gems/rating changes are applied again. VQ is responsible for using idempotency keys to prevent unintended re-runs.

### Claude's Discretion
- Postgres transaction structure and RPC design (atomic upsert patterns)
- Exact HTTP status codes for edge cases not specified above
- Internal logging/observability for the endpoint

</decisions>

<specifics>
## Specific Ideas

- No specific references or product analogues were called out — open to standard patterns
- VQ integration key auth follows the Bearer pattern established in Phase 22

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 28-vq-confirmation-flow*
*Context gathered: 2026-03-15*
