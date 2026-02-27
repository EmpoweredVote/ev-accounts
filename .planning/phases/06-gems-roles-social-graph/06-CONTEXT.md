# Phase 6: Gems, Roles, and Social Graph - Context

**Gathered:** 2026-02-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Build three interlocking systems: a civic economy (gem ledger with 3 types + XP placeholder), civic function assignment (role system with tier eligibility and soft revocation), and social connections (unified social_relationships table covering both unidirectional follows and bidirectional peer connections). The peer connection table also enables the compass visibility enforcement deferred from Phase 4. Spending mechanics for gems, feed rendering, and Inform-tier public discovery endpoints are out of scope for this phase.

</domain>

<decisions>
## Implementation Decisions

### Gem Ledger — Types and Schema
- 3 gem types: **Red** (impact), **Blue** (value), **Yellow** (predictive)
- **XP deferred** — add `xp_total` as a placeholder column on the appropriate user record; full XP ledger deferred until use cases are clearer
- Reserve cap: **deferred entirely** — no cap enforcement in Phase 6; omit the cap column until spending mechanics are designed
- Schema pattern: Claude's discretion (one ledger with `gem_type` column is the simplest; supports concurrent debit enforcement per type via per-type row locks or advisory locks in RPC)

### Gem Ledger — Sources and Triggers
- **Credit sources**: stipend (periodic system grant) + feature participation rewards + admin manual grants
- First feature participation rewards to implement: account Connecting, playing Civic Trivia Championships (CTC), giving helpful feedback on question/answer quality
- **Trigger pattern**: Build a clean `creditGems(userId, gemType, amount, transactionType, sourceRef)` service function that is caller-agnostic — cron jobs, inline route handlers, and future event workers all call the same function. Phase 6 implements the service layer; cron-based awards arrive in Phase 7
- **Debit**: Implement atomic debit enforcement (negative balance rejection) even though no spend targets exist in Phase 6 — the ledger must be production-ready

### Gem Ledger — User-Facing API
- **Expose in Phase 6**: `GET /api/gems/balance` (returns `{ red, blue, yellow }`) + transaction history endpoint
- No spending endpoints in Phase 6 (deferred)

### Role System — Storage
- Roles stored as **rows in a `roles` table** (id, name, slug, required_tier, description). Adding new roles = inserting rows, no migration required. Supports placeholder roles immediately.

### Role System — Alpha Roles
- **Contributor**: data input role — writes to topics/stances are attributed to the user holding this role
- **Candidate**: civic/political leaders; makes them more discoverable; `required_tier = NULL` for Alpha (admin grants to any tier); will tighten to `'empowered'` in a future phase
- **Maven**: from requirements; requires Empowered tier
- **Educator**, **Journalist**: insert as placeholder rows with `is_active = false`; no enforcement logic needed for placeholders

### Role System — Grant and Revocation
- Soft revocation: `user_roles.revoked_at` timestamp (row preserved, history intact). Active roles = `WHERE revoked_at IS NULL`
- Re-granting a revoked role: insert a new row (don't reuse/update the old one — preserves full history)
- Tier eligibility enforcement at grant time: reject grant if `roles.required_tier` is non-null AND user's current tier doesn't meet it; return clear rejection message

### Peer Connections — State Machine
- States: `pending`, `accepted`, `declined`, `blocked` — exactly these four, no additional states
- Any two Connected+ users (Connected or Empowered) can send peer connection requests
- **Block behavior differentiates by tier of the blocker**:
  - If the **blocker is Connected**: blocked user sees nothing — full mutual invisibility for Connected profiles
  - If the **blocker is Empowered**: blocked user cannot send new requests, but the Empowered account's public Candidate page remains accessible (Empowered = public figures, stays discoverable)
- After blocking, neither user can send a new request to the other (bidirectional enforcement per roadmap)
- Accepted peer connection unlocks: **compass visibility** (peer can see each other's compass stances) + **feed access** (activity surfaces in each other's feed)

### Social Graph — Unified Table
- **One `social_relationships` table** with `connection_type` column: `'follow'` (unidirectional, no approval needed) or `'peer'` (bidirectional, requires accept/decline state machine)
- Follows: Connected+ users can follow any Empowered account without approval; no follow between two Connected users — that path goes through the peer connection flow
- Peers: Connected+ users send/accept/decline/block requests to any other Connected+ user

### Social Graph — Privacy Model
- **Empowered = transparency**: an Empowered account's follows are publicly visible (who they follow is public); they do NOT see the list of who follows them (Connected followers retain privacy)
- **Connected = privacy**: a Connected user's connections and follows are not publicly visible by default
- Follower count on Empowered profiles: public. Follower list: not exposed.

### Claude's Discretion
- Schema placement (which Postgres schema — likely `public` or a new `social` schema)
- Exact `creditGems()` RPC vs. service-layer implementation pattern
- Whether `social_relationships` uses a state machine column for peers or separate `peer_connection_requests` + `peer_connections` tables
- Inform-tier API access: scope Phase 6 to authenticated routes only; public Candidate page data deferred to Phase 8

</decisions>

<specifics>
## Specific Ideas

- "We are exploring lots during the alpha and need flexibility" — gem reward rules must be configurable without code deploys. The `transaction_type` and `source_ref` fields on the ledger should be extensible strings/enums, not hard-coded.
- Gem types map to civic values: Red = impact (doing things that matter), Blue = value (demonstrating knowledge/engagement), Yellow = predictive (being right about facts/outcomes, Polymarket-style). This framing should inform naming and descriptions in the roles/gem schema.
- Yellow gems → future "Public Common Ground" feature (fact investment, shared diligence, reward correct predictions). The ledger must support zero-sum debit/credit cycles eventually.
- CTC = Civic Trivia Championships — a recurring engagement feature where gem awards are tied to performance (e.g., 1 Yellow Gem for first CTC round above 80%/day).
- Empowered account visibility principle: "Empowered Accounts default to transparency" — this should be enforced at the RLS/serialization layer, not just convention.

</specifics>

<deferred>
## Deferred Ideas

- Gem spending mechanics (voting on feature priorities, Public Common Ground prediction market) — future phase
- Reserve cap enforcement per gem type — deferred until spending mechanics are designed
- XP ledger with sub-categories (compass XP, social XP, etc.) — placeholder only in Phase 6
- Educator and Journalist roles (functional implementation) — placeholder rows inserted; enforcement logic deferred
- Cron-triggered gem awards (e.g., weekly Blue Gem for 95%+ calibration) — cron infrastructure arrives in Phase 7; Phase 6 builds the service layer the cron will call
- Event-based gem award pipeline — deferred; clean service function in Phase 6 is the foundation
- Inform-tier social discovery API endpoints — Phase 8 handles public-facing access; Phase 6 is authenticated only
- User-to-user compass compare (requires peer_connections table) — Phase 4 deferred this; Phase 6 builds the table so Phase 7 or a patch can wire it up
- Feed rendering and feed API — Phase 6 establishes that accepted peers/follows unlock feed access; feed endpoint itself is a future phase

</deferred>

---

*Phase: 06-gems-roles-social-graph*
*Context gathered: 2026-02-27*
