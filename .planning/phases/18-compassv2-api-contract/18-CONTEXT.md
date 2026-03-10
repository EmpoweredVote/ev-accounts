# Phase 18: CompassV2 API Contract - Context

**Gathered:** 2026-03-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Enable anonymous compass usage and seamless anonymous → connected account migration, while satisfying the CompassV2 API contract so Chris Andrews can migrate CompassV2 to accounts when ready.

This phase does NOT include: migrating CompassV2 itself (Chris Andrews' side), spider graph comparison API, or server-side guest sessions. Those are deferred.

</domain>

<decisions>
## Implementation Decisions

### Anonymous compass mode
- All compass answer routes (`GET /compass/answers`, `POST /compass/answers`, `POST /compass/answers/batch`, `GET /compass/selected-topics`, `PUT /compass/selected-topics`) must work with `optionalAuth` — no 401 for unauthenticated users
- Anonymous users get empty arrays / null responses, not errors
- Anonymous answers live in **browser localStorage only** — no server-side guest sessions for Alpha
- When authenticated, routes behave exactly as they do today

### Guest state migration on signup
- `POST /api/auth/signup` gains an optional `guest_state` field: `{ answers: [{ topic_id, value, write_in_text? }], selected_topics: uuid[] }`
- When `guest_state` is present, answers are atomically migrated to the new user's `compass_responses` after account creation — the user never has to redo their compass
- Migration is atomic (RPC) — either all answers migrate or none do; partial state is not acceptable
- `guest_state` is optional and fully backward-compatible — existing signup calls without it continue to work unchanged

### Decimal compass values (write-in placement)
- `compass_responses.value` changes from `INT CHECK (1–5)` to `NUMERIC(3,1)` with a new CHECK constraint
- Predefined stances stay at integer values 1, 2, 3, 4, 5 — the labeled options don't move
- Write-in answers can be placed at any 0.5-increment between stances: 1.5, 2.5, 3.5, 4.5
- The valid range for write-in placement: 0.5 to 5.5 (one half-step below 1 and above 5 to express "even stronger than the strongest stance")
- `compass_stances.value` stays INT — predefined stances are always whole numbers
- Schema migration must update the CHECK constraint and column type; existing integer data migrates cleanly (integers are valid NUMERIC values)

### /api/account/me shape fix
- `completed_onboarding` added to **root** of the response (in addition to staying inside `connected_profile`)
- This is additive — no existing fields move or are removed; backward-compatible
- `xp` stays nested in `connected_profile` only — CompassV2 does not read `xp` from this endpoint (confirmed by codebase analysis)
- Inform-tier users (no `connected_profile`) get `completed_onboarding: false` at root

### COMPASS_CONTRACT.md
- Written as an **external-facing document for Chris Andrews** to use when migrating CompassV2
- Must include: base URL, auth method (Bearer token — how to get it from Supabase login), all compass endpoint paths, request/response shapes for each route, guest state migration shape, error codes
- Written at a level where Chris Andrews can read it and know exactly what to change in his frontend code
- Location: repo root or `/docs/` — somewhere Chris Andrews can easily find it

### Claude's Discretion
- Exact valid range for decimal write-in values (0.5–5.5 vs. 1.0–5.0) — go with 0.5–5.5 to give maximum expressiveness
- Whether to also update `compass_change_history.old_value` / `new_value` columns to NUMERIC(3,1) for consistency
- COMPASS_CONTRACT.md exact format and level of detail

</decisions>

<specifics>
## Specific Ideas

- "I want someone to be able to use their compass and decide to create an account, and it captured all the stuff they had just said and they wouldn't have to redo their compass." — This is the north star for the guest state migration feature.
- The anonymous → connected handoff is the same pattern Chris Andrews already implemented in CompassV2's `guest_state` on `/auth/register`. We're building the accounts equivalent.
- Platform philosophy: anonymous users are a first-class experience, not second-class. The compass is an Inform-tier feature — it must work without any account.
- JWT/Bearer is the right call over cookies for this platform: multiple apps on different domains (CompassV2, Essentials, CTC, VQ) all need to call accounts. Cookies require same-domain or complex CORS setup; bearer tokens are clean across origins and work for future mobile apps.
- Decimal values context: predefined stances stay at integers 1–5 (the labeled positions); write-ins can be placed between them at 0.5 increments. This is the full compass model.

</specifics>

<deferred>
## Deferred Ideas

- **Full CompassV2 migration** — Chris Andrews' side; he will use COMPASS_CONTRACT.md when usability tests are done (2 weeks)
- **Spider graph comparison API** — comparing user spider graph against politician spider graphs; depends on Phase 21 (empowered_profiles politician schema) being complete first
- **Server-side guest sessions** — temporary guest ID with server-stored answers; not needed for Alpha; localStorage is sufficient
- **Username → display_name reconciliation** — CompassV2 reads `data.username` from its current API; when CV2 migrates, it updates to `display_name`; no action needed on accounts side
- **CTC and Validation Quests compass integration** — these apps already use accounts; compass answers are already accessible via existing routes
- **Alternative auth methods** (passkeys, phone) — email/password is correct for Alpha; revisit at v2
- **Essentials, Treasury Tracker, Read & Rank migration** — Chris Andrews' other features; same migration path as CV2 but separate work

</deferred>

---

*Phase: 18-compassv2-api-contract*
*Context gathered: 2026-03-09*
