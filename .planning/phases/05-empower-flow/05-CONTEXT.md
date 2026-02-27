# Phase 5: Empower Flow - Context

**Gathered:** 2026-02-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Empowerment and demotion lifecycle — Connected users transition to Empowered tier via preflight check + atomic confirm, and can be demoted back to Connected. Includes: preflight validation, slug reservation, atomic empowerment (via execute_empowerment RPC), atomic demotion (via execute_demotion RPC), and re-empowerment path. Public candidate pages are Phase 8.

Note: Connected accounts require NO compass calibration to connect. Compass calibration is only a requirement for empowerment.

</domain>

<decisions>
## Implementation Decisions

### Preflight failure feedback
- Return ALL failures at once — user sees every unmet condition in a single call, not just the first
- Structured error codes + human messages: `{ code: 'CALIBRATION_INCOMPLETE', message: '...', threshold: N, current: N }` — frontend can act on code programmatically
- Success response: `{ eligible: true, summary: { legal_name, compass_completeness, slug_preview } }` — full summary to prime the confirm screen UI
- Conditions checked: (1) verified status on connected_profiles, (2) role-specific calibration threshold met (role stored on profile before preflight is called), (3) legal name on file, (4) consent captured

### Consent
- User must explicitly consent to three things: legal name published publicly, compass stances made public, platform terms/candidate pledge
- Durable record with timestamp required — `consent_given_at` stored (on empowered_profiles or dedicated consent record). Auditable proof of agreement.
- HOW consent is captured in the API (flag in confirm body vs. separate endpoint): Claude's discretion

### Slug behavior
- Suffix applied **always** — every slug is `first-last-XXXX` format regardless of collision. Consistent, no conditional logic.
- User can request a regenerate — frontend calls preflight again to get a new random suffix if the user doesn't like the preview
- Slug **reserved at preflight** — guaranteed to be the same slug used at confirm. Reservation TTL: **1 hour**
- Demoted users who re-empower get their **original slug restored** — not a new slug. Prior links remain valid.

### Post-demotion state
- `GET /api/account/me` for a demoted user returns: `{ tier: 'connected', empowerment_status: 'demoted', demoted_at: <timestamp> }` — rich enough for a tailored re-empowerment UI
- `POST /api/empower/preflight` for a demoted user: surfaces demotion reason (which topics lapsed or what condition triggered it) AND the current conditions check. Not just a pass/fail — user understands what happened and what they need to fix.
- Re-empowerment path is the same preflight + confirm flow. No separate re-empower endpoint needed.

### Claude's Discretion
- Exact API shape for consent capture (flag in confirm body vs. separate /consent endpoint)
- Where `consent_given_at` is stored (on empowered_profiles vs. separate consent_records table)
- Exact field names for demotion reason in preflight response
- Exact error code strings (e.g., `CALIBRATION_INCOMPLETE` vs `CALIBRATION_THRESHOLD_NOT_MET`)
- Slug reservation storage mechanism (Redis vs. DB table with expiry)

</decisions>

<specifics>
## Specific Ideas

- Preflight success response is designed as a "confirm screen data payload" — the frontend doesn't need to make additional calls to display what empowerment will do to the user. It should carry `{ legal_name, compass_completeness, slug_preview }` at minimum.
- Demotion reason in preflight should be specific (e.g., which topics lapsed), not generic. User must understand why they were demoted and what they need to recalibrate.
- Role-level for calibration threshold is stored on the user's profile before they ever call preflight — the preflight call itself doesn't accept a role parameter.

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-empower-flow*
*Context gathered: 2026-02-27*
