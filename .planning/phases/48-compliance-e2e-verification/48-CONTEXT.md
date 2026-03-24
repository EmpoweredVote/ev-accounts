# Phase 48: Compliance + End-to-End Verification - Context

**Gathered:** 2026-03-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Disclose the `ev_session` cookie in a new privacy policy page on `accounts.empowered.vote` (classifying it as strictly necessary — no consent banner required), then run a manual E2E smoke test confirming SSO works across all five apps. Creating posts, changing auth, or adding new SSO behavior are out of scope — this phase only documents and verifies what's already shipped.

</domain>

<decisions>
## Implementation Decisions

### Privacy disclosure location
- Create a new `/privacy` React route — no privacy page exists yet
- Fully public route — no authentication required to access it
- Footer link on all pages of `accounts.empowered.vote` links to `/privacy`
- Cookie disclosure lives as a dedicated section within the full privacy policy page (not a standalone cookie-only page)

### Privacy policy scope
- Full privacy policy + cookie disclosure section on the same `/privacy` page
- Covers: data handling, user rights, third-party services, and the cookie table
- User rights section: link to account settings for self-service actions (profile edits, account deletion); contact email for anything else (access requests, data export, etc.)

### Cookie disclosure content
- Table format with fields: Name | Purpose | Domain | Duration | Type | Classification
- `ev_session` details:
  - **Purpose:** Session continuity across Empowered Vote apps
  - **Domain:** `.empowered.vote`
  - **Duration:** Session (until logout or browser close)
  - **Type:** First-party, HttpOnly, Secure, SameSite=Lax
  - **Classification:** Strictly necessary — no consent banner required

### Smoke test format
- Script lives at `docs/SSO-SMOKE-TEST.md` — committed to the repo as a reusable reference
- Structure: linear flow — one login at `accounts.empowered.vote`, then visit all five apps in sequence (Profile Hub → CTC → Essentials → CompassV2 → VQ)
- Coverage: happy path (session inherited) + graceful degradation (Inform-baseline when no session present)
- Results section logs: run date, browser + version, environment (production), pass/fail per step

### Pass/fail criteria & sign-off
- Completion artifact: filled-in `docs/SSO-SMOKE-TEST.md` committed to git (checked boxes + run metadata)
- Environment: production only — Phase 48 verifies what's already shipped
- Failure protocol: if one app fails, document the failure inline, continue verifying remaining apps, then create a targeted fix task. Phase 48 stays incomplete until a clean re-run passes. (Stop-and-fix-everything is too disruptive when the failure may be isolated to one app.)

### Claude's Discretion
- Exact prose wording of the privacy policy sections
- Visual layout/styling of the `/privacy` page (use existing Tailwind patterns from the accounts app)
- Contact email to use for data rights requests — check existing codebase for any established contact address

</decisions>

<specifics>
## Specific Ideas

- The `ev_session` cookie is "strictly necessary" under GDPR/ePrivacy Directive — document this classification explicitly so it's clear no opt-in banner is required
- The smoke test should mirror the exact success criteria from ROADMAP.md Phase 48 — each criterion becomes a checklist item
- `docs/SSO-SMOKE-TEST.md` should be written as a reusable script (future regression testing), not a one-off artifact

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 48-compliance-e2e-verification*
*Context gathered: 2026-03-24*
