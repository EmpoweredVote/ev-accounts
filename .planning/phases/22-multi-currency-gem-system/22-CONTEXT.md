# Phase 22: Multi-Currency Gem System - Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend the gem ledger to three currencies (yellow/blue/red) with three balance columns on `connected_profiles`, a new `POST /api/gems/award` service-to-service endpoint with service key auth, and a `GET /api/account/me` response update replacing the legacy `gem_balance` integer with `gems: { yellow, blue, red }`. Admin tool displays three separate balances.

</domain>

<decisions>
## Implementation Decisions

### Legacy gem_balance migration
- Drop `gem_balance` entirely from `GET /api/account/me` — no backward compatibility shim
- Leave the `gem_balance` column in the DB (don't migrate it out) — just stop selecting it in the API
- `database.types.ts`: `yellow_gem_balance`, `blue_gem_balance`, `red_gem_balance` are `number` (not `number | null`) in the Row type — they are NOT NULL DEFAULT 0 in the DB
- Admin tool account detail page: three labeled values inline — `Yellow: 42  Blue: 0  Red: 7`; same visual weight as previous single balance

### POST /api/gems/award — request shape
- Body: `{ user_id, gem_type, amount, idempotency_key }`
- `idempotency_key` is **required** — award is rejected with 422 if omitted
- `user_id` is the target recipient — service keys don't have a "self" to award to
- Service-to-service only (`Authorization: Bearer <service-key>`) — regular user JWTs rejected with 401

### Duplicate detection
- Dedup via idempotency_key stored on the gem_transactions row
- Dedup scope: per `idempotency_key` alone (not per key + gem_type)
- Duplicate response: HTTP 200, same response shape — `{ gem_type, amount, new_balance, is_duplicate: true }`
- Duplicate detection is permanent (no TTL — key is stored forever on the transaction row)

### Service key permissions
- Configured via `GEMS_SERVICE_KEYS` env var — JSON map: `{ "ctc-key-abc": ["yellow"], "vq-key-xyz": ["yellow", "red"] }`
- Two service keys for Phase 22: CTC (permitted: `["yellow"]`), VQ (permitted: `["yellow", "red"]`)
- Forbidden type response: HTTP 422 `{ error: 'FORBIDDEN_GEM_TYPE', permitted: ['yellow'] }` — includes what the key IS permitted to do
- Endpoint supports all three gem types (`'yellow' | 'blue' | 'red'`) from day one — no code change needed when blue issuer comes online

### Gem type semantics (inform downstream logic)
- **Yellow gems** = knowledge validation. Awarded for validating known facts (e.g., "Who is your Mayor?") with correct answers and quality sourcing. Awarded by: CTC and VQ.
- **Red gems** = frontier/open quests. Awarded for contributing to unanswered questions — requires sufficient yellow gem credibility to unlock. Awarded by: VQ only.
- **Blue gems** = value-based decisions / voting preference across Inform→Connect→Empower tiers. No issuing service in Phase 22 — balance columns added to schema, endpoint supports the type, but no service key configured for blue yet.

### Claude's Discretion
- Advisory lock pattern for concurrent gem writes (existing pattern from Phase 6 — extend it)
- Exact `GEMS_SERVICE_KEYS` parsing/validation at startup (process.exit(1) if malformed, like GOOGLE_MAPS_API_KEY)
- gem_transactions row shape for the new `gem_type` ENUM column
- Integration test structure for the balance-always-0 bug fix verification

</decisions>

<specifics>
## Specific Ideas

- "CTC should migrate off the direct `connect.credit_gems` RPC to this endpoint" — this phase forces that migration
- The `is_duplicate: true` flag in the response body is the canonical way CTC detects replays — no separate status code needed
- Blue gems are reserved for a governance/voting mechanic down the line ("powerful things") — schema is the right investment now, even without an issuer

</specifics>

<deferred>
## Deferred Ideas

- Blue gem issuing service — no service awards blue gems in Phase 22; reserved for a future voting/governance mechanic
- Admin manual gem award UI — admins cannot manually award gems via the admin tool in this phase; that belongs in Phase 23 (Admin Tier Promotion) or its own phase
- Service key management UI — keys are managed via env var for Alpha; a key management UI would be its own phase

</deferred>

---

*Phase: 22-multi-currency-gem-system*
*Context gathered: 2026-03-14*
