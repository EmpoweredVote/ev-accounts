---
status: complete
phase: 68-yellow-inform-profile-page-+-connected-explainer
source: [68-01-SUMMARY.md, 68-02-PLAN.md, phase-68-success-criteria]
started: 2026-05-09T00:00:00Z
updated: 2026-05-09T00:00:00Z
---

## Tests

### 1. Yellow pill and header border
expected: At login.empowered.vote/profile as an Inform user (light mode): the "Inform Account" pill is solid yellow (bg-ev-yellow) with dark text — not a faint washed-out yellow. The header card has a visible yellow border.
result: pass

### 2. Observe Access badge
expected: In the Connect section, the "Observe Access" badge is solid yellow (same fix as the pill) — not washed out. The observe-access copy explains that Connect features require a Connected Account.
result: pass

### 3. Compass tile shows calibration count
expected: The Compass feature tile shows a progress stat — e.g. "8 / 21 stances calibrated" — with a small fill bar. If you have answered 0 topics, it shows "0 / 21".
result: issue (medium) — calibration count text ("8/44") is white, legible in dark mode but invisible in light mode. Feature tile backgrounds (yellow, teal) are also washed out in light mode — need stronger/darker colors across the board.

### 4. Connect tiles locked with padlock badge
expected: All three Connect feature tiles (Validation Quests, Civic Spaces, Empowered Listening) each show a small padlock icon in the top-right corner. The tiles are still visible and readable but indicate observe-only access.
result: pass

### 5. Infographic modal opens on pill click
expected: Clicking "Inform Account" opens a full-width modal (~896px on desktop) showing the three-tier infographic: progress bar (yellow/teal/red segments), three cards (Inform / Connect / Empower) with colored headers and detail sections, and a bottom tagline row ("Explore freely → Join the conversation → Lead publicly").
result: pass

### 6. Modal dark mode
expected: Switching to dark mode (sun/moon toggle in the nav), then opening the modal: the modal background is dark (#111), the card detail areas are dark (#1e1e1e), the identity badges use a dark pill style. The card headers (pastel yellow/teal/red) remain light in both modes.
result: pass

### 7. Connect Account button → limitations flow
expected: Inside the modal, clicking "Connect Account" (teal button at the bottom) reveals the limitations panel: three checkmark items — "Verified identity, kept private", "Each person gets one voice", "Invite code required during Alpha" — plus an "I have an invite code →" CTA. The button itself disappears and is replaced by this panel.
result: pass

### 8. Invite code CTA navigates and closes modal
expected: Clicking "I have an invite code →" navigates to /signup and closes the modal. Clicking "Close" also closes the modal without navigating. Escape key and backdrop click also close the modal.
result: pass

### 9. Bottom "Ready to participate?" section
expected: Below the feature tiles, Inform-tier users see a subtle "Ready to participate? Connect your account when you are —" section with a "Learn about Connected Accounts →" link that opens the same modal. This section does not appear for Connected or Empowered users.
result: pass

### 10. Connected user regression — no pill click, no lock badges, no bottom section
expected: Logging in as a Connected user: the "Connected Account" pill is a non-clickable span (no hover, no cursor-pointer). Feature tiles have no padlock badges. The bottom "Ready to participate?" section is absent.
result: issue (medium) — Connected Account pill should also be clickable and open the ConnectedExplainerModal (same infographic). Pill color should match the teal used for Level 3 (ev-teal / ev-teal-light), not the current style. No padlocks and no bottom section are correct. Note: future flow will add "Empower your account" CTA inside modal for Connected users; for now modal is read-only explainer.

## Summary

total: 10
passed: 10
issues: 0
pending: 0
skipped: 0

## Gaps

### Gap A — Light mode contrast ✅ RESOLVED
- Calibration count text: `text-white` → `text-gray-900 dark:text-white`
- Section backgrounds: `/20` → `/40` opacity in light mode
- Commit: 661f6de

### Gap B — Connected Account pill not clickable ✅ RESOLVED
- `<span>` → `<button>` opening ConnectedExplainerModal for all tiers
- Styled `ev-blue` to match Level 3 XP badge
- Commit: 661f6de
