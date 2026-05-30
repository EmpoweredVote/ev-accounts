# Phase 62: Onboarding Restyle - Context

**Gathered:** 2026-04-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Restyle the active onboarding steps with v2.0 design language (AppNav, StepProgress, AuthCard, AuthInput, PrimaryButton) and copy that frames civic participation as meaningful, not transactional. `WelcomeStep` is removed from the flow — `/welcome` (Phase 61) absorbs that role.

This phase does NOT add new onboarding steps, change the Connected tier entry requirements, or modify the backend signup logic.

</domain>

<decisions>
## Implementation Decisions

### PseudonymStep — removed

Phase 61 added `display_name` to the SignupPage form (fifth field) and stores it at account creation via migration 071. `PseudonymStep` in onboarding would ask for a name the user already gave. **Remove it entirely.** Do not render it; do not route through it.

The active onboarding sequence is now two steps: **LocationStep → LocationCelebrationStep**.

### Step counter

The full signup + onboarding journey is three steps. Phase 62 must also patch SignupPage (Phase 61 work) to update StepProgress from `1 of 4` → `1 of 3`:

- SignupPage: `Step 1 of 3` ← update as part of this phase
- LocationStep: `Step 2 of 3`
- LocationCelebrationStep: `Step 3 of 3`

### Location — required, no skip

Location is required to complete onboarding. No skip option. If geocoding fails or returns no match, the user sees an inline error and must correct their address and retry. There is no path forward without a valid geocoded address.

### Location step copy

The roadmap draft included "Learn More." at the end of the location step helper text — **omit it entirely.** The copy is just:

> "We use your location to connect you with your local civic space."

No link, no "Learn More." Cleaner and avoids a dead link.

### Celebration step copy — civic + active

Three milestone confirmation items, civic and active in tone:

1. "Your Connected Account is live"
2. "Your civic community is located"
3. "You're ready to participate"

Green checkmark icon beside each. "Go to dashboard" CTA at the bottom.

### Claude's Discretion

- Placeholder text for LocationStep's four address fields (street, city, state, ZIP)
- Inline validation error messages (e.g., required fields, unrecognized address)
- Exact spacing, icon sizing, and animation (if any) on the celebration step
- Whether the Back button on LocationStep navigates to signup or is hidden

</decisions>

<specifics>
## Specific Ideas

- Celebration step: the green checkmark and milestone list should feel like a reward, not a form confirmation — the user earned this
- Copy throughout should invite participation, never pressure it — consistent with the anti-funnel principle from STATE.md
- The four address fields on LocationStep use `AuthInput` with no ZIP-only shortcut; all four fields are present and required

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 62-onboarding-restyle*
*Context gathered: 2026-04-25*
