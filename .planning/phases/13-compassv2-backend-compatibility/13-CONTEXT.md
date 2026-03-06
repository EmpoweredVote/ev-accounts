# Phase 13: CompassV2 Backend Compatibility - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Close three specific API gaps so CompassV2 can fully function against this backend without workarounds:
1. `DELETE /api/compass/answers/me` — reset a user's compass answers and selected topics
2. `GET /api/essentials/politicians` — unauthenticated list of politicians (with optional candidate support)
3. `POST /api/connect/compass-import` — import calibrations + selected_topics for a user

Schema additions to `inform.politicians` are in scope to support candidate grouping.

</domain>

<decisions>
## Implementation Decisions

### Answer Reset (DELETE /api/compass/answers/me)

- **Soft delete** — mark rows with `deleted_at`, do not hard-delete. Preserves data for potential recovery.
- **Change history preserved** — `compass_change_history` rows are NOT wiped. Audit trail survives a reset.
- **Default behavior:** clears `compass_responses` (soft) + `inform_selected_topics` for the user. Does NOT touch `completed_onboarding`.
- **Full reset mode:** `DELETE /api/compass/answers/me?full=true` — admin-only flag that additionally resets `completed_onboarding = false` on `connected_profiles`. Used for admin "quick demo reset" flow (UI wired in Phase 15).
- **HTTP status:** 200 for all cases including already-empty state (idempotent delete).
- **Atomicity:** Wrap in a transaction — if any step fails, roll back entirely (Claude's discretion).

### Politicians Endpoint (GET /api/essentials/politicians)

- **Unauthenticated** — no Authorization header required.
- **Active politicians by default** — filter to `is_active = true`.
- **Candidate support:** Add `is_candidate boolean` column to `inform.politicians`. Candidates (challengers running for a role) are distinct from incumbents.
- **Response shape:** grouped by `office_title` — `{ office_title, incumbent: {...}, candidates: [...] }`. Allows CompassV2 to show "Karen Bass (Mayor) + challenger cards" in one block.
- **Optional filter:** `?include_candidates=true` — when absent, return incumbents only (`is_candidate = false`). Supports both use cases (incumbent-only vs full race view).
- **Fields per politician:** `id, full_name, office_title, photo_origin_url, is_candidate`
- **Default sort:** by `office_title` then `full_name` (alphabetical within office group).
- **Rate limiting:** infra-level (Render/Nginx) — no code-level rate limiting on this route (Claude's discretion, consistent with existing patterns).
- **Error handling:** return proper status codes (503/429) with error body — never silently return empty array on infrastructure failure (Claude's discretion).

### Compass Import (POST /api/connect/compass-import)

- **Merge behavior:** upsert by `topic_id` — imported calibrations update existing answers if present, insert if missing. Answers for topics NOT in the payload are untouched.
- **Who can call:**
  - Authenticated user calling for themselves (no `user_id` body field needed — use JWT subject)
  - Admin calling for another user by providing `user_id` in the request body
- **Invalid calibrations:** atomic — if any row fails validation (value out of range, topic_id doesn't exist), reject the entire import with 400. Nothing is written (Claude's discretion).
- **`completed_onboarding` after import:** Claude's discretion — auto-set to true if the import includes a valid `selected_topics` array meeting the 3–8 topic minimum threshold.

### Error Contracts

- **Match existing error shape** across all three endpoints (audit existing patterns, stay consistent).
- **Admin user_id not found:** 404 with standard error body (Claude's discretion).
- **DELETE atomicity:** transaction-wrapped, roll back on failure (Claude's discretion).

### Claude's Discretion

- HTTP 200 vs 204 for delete — using 200 (idempotent, matches success criteria spec)
- Rate limiting approach — infra-level
- Atomic import failure mode — reject all, return 400
- `completed_onboarding` auto-set — yes, when selected_topics threshold met
- Error body on DB unavailable for unauthenticated route — proper status codes, not silent empty array
- Transaction strategy for soft-delete — wrap all steps in single transaction

</decisions>

<specifics>
## Specific Ideas

- Admin "quick demo reset" use case: admin frequently demos the compass to new people with a partially-answered account; they need a subtle one-click full reset (answers + onboarding) accessible from the main compass screen. Should be visually clear to admins but not distracting — not a prominent button for regular users. Phase 15 wires the UI; Phase 13 provides the `?full=true` backend flag.
- Politicians grouped by office (`{ office_title, incumbent, candidates[] }`) is the response shape CompassV2 needs to render race-aware comparisons.
- The `?include_candidates=true` query param allows the same endpoint to serve both the "just show my reps" use case and the "show the full race" use case.

</specifics>

<deferred>
## Deferred Ideas

- Regular user account reset via profile page with "Are you sure?" confirmation dialog — this is a Phase 15 (React UI) concern. The backend `DELETE /compass/answers/me` (without `?full=true`) already supports it; only the UI is deferred.
- Election cycle / race metadata (which candidates are running in which election) — the `is_candidate` flag added here is the foundation, but full race/election modeling is a future phase.
- Candidate sort toggle with icon + tooltip (swap between alphabetical and office-grouped) — Phase 15 React UI feature. Backend already returns both orderable fields.

</deferred>

---

*Phase: 13-compassv2-backend-compatibility*
*Context gathered: 2026-03-06*
