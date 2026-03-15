# Phase 29: Admin Controls & Integration Verification - Context

**Gathered:** 2026-03-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Admins can view and manually override a user's `verification_rating` and clear `vq_hold_until` via the admin tool UI. CTC and VQ live integrations are verified end-to-end with a smoke test runbook. The `/vq/confirm-stance` endpoint is documented for VQ developers in `docs/ONBOARDING-VQ.md`.

New capabilities (e.g., VR history/audit trail, automated integration test pipeline) are out of scope for this phase.

</domain>

<decisions>
## Implementation Decisions

### Admin VR editor — placement
- Inline on the existing user detail page, alongside tier, XP, and gems
- No new section, tab, or modal — same visual weight as other user fields

### Admin VR editor — interaction model
- Edit mode toggle: an "Edit" button puts the VR fields into an editable state
- Admin changes `verification_rating` (number input) and can clear `vq_hold_until` (button)
- "Save" commits changes; "Cancel" discards them — explicit two-step, no auto-save

### Admin VR editor — context shown
- Display `verification_rating` value and `vq_hold_until` date (or "None")
- Show derived status badges alongside:
  - "Hold active" (orange badge) when `vq_hold_until` is in the future
  - "Red Gems unlocked" (red badge) when `verification_rating` >= 90
- Badges visible in both view and edit mode

### Admin VR editor — validation
- Validate input range 0–150 in the UI; save button disabled until valid
- Inline error shown for out-of-range values (e.g., "Must be between 0 and 150")
- Do not silently clamp — surfacing the error is more honest

### Smoke test format — document
- Manual checklist runbook: `docs/SMOKE-TEST-INTEG.md`
- Step-by-step instructions with expected outputs and checkboxes
- Separate from the VQ onboarding doc (different audience: ops vs. VQ devs)

### Smoke test format — CTC blocker handling (INTEG-01)
- Write the full CTC runbook steps this phase
- Include a clear prerequisite callout: "Requires CTC_SERVICE_KEY set in Render env (see STATE.md open blockers)"
- Phase ships with runbook written; Chris verifies async once key is configured
- Phase is NOT gated on live CTC verification completing

### Smoke test format — VQ verification depth (INTEG-02)
- Full flow: prerequisites → confirmation call → admin tool verification → idempotency replay test
- Prerequisites section: env vars needed, test user setup, politician + topic in DB
- Include exact sample payload (with real-looking test UUIDs)
- Verification checklist: gem balance increased, VR badge updated in admin, hold state correct
- Idempotency replay: same call again → same response body, no additional DB writes

### VQ onboarding doc — orientation
- Quick start + field reference style (`docs/ONBOARDING-VQ.md`)
- Leads with: authentication setup (Bearer token + service key) and a complete working example
- Field reference covers all request fields with types, constraints, and non-obvious behavior
- "Stripe API docs for one endpoint" quality target

### VQ onboarding doc — side effects section
- Each side effect documented with exact numbers and edge cases:
  - Correct users: +X Red Gems awarded
  - Correct users: `verification_rating` increases by 3 (max 150)
  - Incorrect users: `verification_rating` decreases by 10 (min 0); hitting 0 sets `vq_hold_until` = now + 30 days
  - Confirmed stance written to `inform.politician_answers` as authoritative record
  - Idempotent replay: same `idempotency_key` returns original result, no additional writes
- Concrete examples for edge cases (e.g., rating = 5, incorrect → rating = 0, hold set)

### VQ onboarding doc — error documentation
- Document key errors explicitly:
  - 401: bad or missing service key (with example response body)
  - 400: malformed payload (missing required fields — with example)
  - Idempotency conflict: same key, different payload → explicit error case explained
- Generic note for other errors: "Additional errors return standard HTTP codes with `{ error: string }` body"

### VQ onboarding doc — versioning
- "Last updated: 2026-03-16" datestamp in the header
- Single note: "This documents the current API contract. Breaking changes will be communicated before deployment."
- No running changelog for Alpha

### Claude's Discretion
- Exact badge styling (use ev-red for "Red Gems unlocked", ev-yellow or orange for "Hold active" — within established brand tokens)
- Layout and spacing of the VR section within the user detail card
- Exact formatting/template structure of the SMOKE-TEST-INTEG.md runbook
- Red Gem amount per correct user (not specified — use whatever Phase 28 established)

</decisions>

<specifics>
## Specific Ideas

- Admin edit model should feel consistent with how other fields are edited in the existing admin tool (Phase 14/15 compass admin set the pattern — use the same save/cancel flow)
- ONBOARDING-VQ.md quality target: "Stripe API docs for a single endpoint" — a VQ dev should be able to implement the integration without asking a follow-up question
- The idempotency replay test in the VQ smoke test is critical to verify in production — that's the key Phase 28 guarantee (VQ-05)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 29-admin-controls-integration-verification*
*Context gathered: 2026-03-15*
