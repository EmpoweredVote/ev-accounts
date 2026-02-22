# Phase 25: Onboarding-to-Calibration Redirect & Topic Display Fix - Context

**Gathered:** 2026-02-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Two fixes: (1) After onboarding, users are incorrectly sent to /results where they see a "need 3 more topics" message — they should instead go directly into the calibration flow. (2) Topic/issue cards are not displaying anywhere on the site — a regression likely introduced during Phase 24 tech debt cleanup. This phase restores correct flow routing and fixes the card display regression.

</domain>

<decisions>
## Implementation Decisions

### Redirect behavior
- After onboarding completes, redirect to the "Calibrate your compass" flow instead of /results
- Onboarding itself works correctly — only the final redirect destination is wrong
- Calibration has its own topic selection step (user picks which 3+ topics to answer)
- After calibration completes (3+ topics answered), redirect to /results to show the radar chart
- Happy path: Onboarding → Calibration (pick & answer 3+ topics) → /results (radar chart)

### Topic card regression
- Topic/issue cards are not showing up anywhere on the site — completely invisible
- This is a recent regression, cards were working before
- Likely caused by Phase 24 tech debt cleanup changes
- Fix should restore cards to their previous working appearance — no visual changes needed
- Priority: Fix topic cards first, then fix the redirect

### Flow edge cases
- Guests and logged-in users follow the same onboarding → calibration → results flow
- If a user has completed onboarding and returns, skip onboarding (don't show it again)
- If a user completed onboarding but hasn't calibrated, resume calibration automatically on return
- Back button during calibration should only navigate back through calibration steps — not exit to onboarding or library

### Claude's Discretion
- Technical approach to identifying the card regression root cause
- Implementation of the redirect logic (route guards, state checks, etc.)
- How "onboarding complete" and "calibration complete" states are tracked/detected

</decisions>

<specifics>
## Specific Ideas

- The /results page currently shows a "need 3 more topics" message for uncalibrated users — this message itself isn't wrong, but users shouldn't reach it from onboarding
- Topic cards worked before Phase 24, so the fix is likely restoring something that was accidentally removed or broken during the tech debt cleanup

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 25-onboarding-to-calibration-redirect-topic-display-fix*
*Context gathered: 2026-02-22*
